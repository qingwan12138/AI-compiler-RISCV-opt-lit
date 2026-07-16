[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Root,

    [ValidateRange(1, 99)]
    [int]$ExpectedNoteSections = 13,

    [string]$PdfInfoPath,

    [switch]$SkipPdfInfo
)

$ErrorActionPreference = 'Stop'
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-ValidationError([string]$Message) {
    $script:errors.Add($Message)
}

function Get-IndexRows([string]$Path) {
    $rows = [System.Collections.Generic.List[object]]::new()
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -notmatch '^\|\s*([A-Za-z]+\d+|\d+)\s*\|') {
            continue
        }
        $cells = @($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
        if ($cells.Count -lt 4) {
            Add-ValidationError "索引行字段不足: $Path :: $line"
            continue
        }
        $rows.Add([pscustomobject]@{
            Id       = $cells[0]
            Year     = $cells[1]
            Category = $cells[2]
            Line     = $line
        })
    }
    return @($rows)
}

function Get-LocalMarkdownTargets([string]$Line, [string]$BaseDirectory) {
    $targets = [System.Collections.Generic.List[string]]::new()
    foreach ($match in [regex]::Matches($Line, '\]\((<[^>]+>|[^)\s]+)\)')) {
        $raw = $match.Groups[1].Value.Trim('<', '>')
        if ($raw -match '^(https?|mailto):' -or $raw.StartsWith('#')) {
            continue
        }
        $pathPart = ($raw -split '#', 2)[0]
        if ([string]::IsNullOrWhiteSpace($pathPart)) {
            continue
        }
        $decoded = [System.Uri]::UnescapeDataString($pathPart)
        $targets.Add([System.IO.Path]::GetFullPath((Join-Path $BaseDirectory $decoded)))
    }
    return @($targets)
}

function Find-PdfInfo([string]$ExplicitPath) {
    if ($ExplicitPath) {
        if (Test-Path -LiteralPath $ExplicitPath) {
            return (Resolve-Path -LiteralPath $ExplicitPath).Path
        }
        Add-ValidationError "指定的 pdfinfo 不存在: $ExplicitPath"
        return $null
    }

    $command = Get-Command pdfinfo.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $runtimeRoot = Join-Path $HOME '.cache/codex-runtimes'
    if (Test-Path -LiteralPath $runtimeRoot) {
        $candidate = Get-ChildItem -LiteralPath $runtimeRoot -Recurse -Filter 'pdfinfo.exe' -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
        if ($candidate) {
            return $candidate
        }
    }
    return $null
}

try {
    $rootPath = (Resolve-Path -LiteralPath $Root).Path
} catch {
    Write-Error "语料库根目录不存在: $Root"
    exit 1
}

$classIndex = Join-Path $rootPath '00_分类索引.md'
$readingIndex = Join-Path $rootPath '文献逐篇阅读/00_逐篇阅读目录.md'
$yearList = Join-Path $rootPath '文献逐篇阅读/2024-2026_文献年份筛选清单.md'
$requiredFiles = @($classIndex, $readingIndex, $yearList)

foreach ($file in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        Add-ValidationError "缺少必需文件: $file"
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Host "ERROR: $_" -ForegroundColor Red }
    exit 1
}

$classRows = @(Get-IndexRows $classIndex)
$readingRows = @(Get-IndexRows $readingIndex)
$classIds = @($classRows.Id | Sort-Object -Unique)
$readingIds = @($readingRows.Id | Sort-Object -Unique)

if ($classRows.Count -ne $classIds.Count) {
    Add-ValidationError "分类索引存在重复编号: 行数 $($classRows.Count)，唯一编号 $($classIds.Count)"
}
if ($readingRows.Count -ne $readingIds.Count) {
    Add-ValidationError "逐篇目录存在重复编号: 行数 $($readingRows.Count)，唯一编号 $($readingIds.Count)"
}

$idDiff = @(Compare-Object -ReferenceObject $classIds -DifferenceObject $readingIds)
if ($idDiff.Count -gt 0) {
    $detail = ($idDiff | ForEach-Object { "$($_.InputObject)[$($_.SideIndicator)]" }) -join ', '
    Add-ValidationError "两个索引的编号集合不一致: $detail"
}

foreach ($indexPath in @($classIndex, $readingIndex)) {
    $text = Get-Content -LiteralPath $indexPath -Raw
    $totals = @([regex]::Matches($text, '\|\s*\*\*合计\*\*\s*\|\s*\*\*(\d+)\*\*') |
        ForEach-Object { [int]$_.Groups[1].Value })
    $expectedCount = if ($indexPath -eq $classIndex) { $classRows.Count } else { $readingRows.Count }
    if ($totals.Count -eq 0) {
        Add-ValidationError "索引缺少合计统计: $indexPath"
    } elseif (@($totals | Where-Object { $_ -ne $expectedCount }).Count -gt 0) {
        Add-ValidationError "索引合计与实际行数不一致: $indexPath，实际 $expectedCount，合计 $($totals -join '/')"
    }

    $rows = if ($indexPath -eq $classIndex) { $classRows } else { $readingRows }
    foreach ($heading in [regex]::Matches($text, '(?m)^##\s+(0[1-6])\s+.*（(\d+)\s+篇）')) {
        $categoryId = $heading.Groups[1].Value
        $declared = [int]$heading.Groups[2].Value
        $actual = @($rows | Where-Object { $_.Category -match "^$categoryId(?:\s|_)" }).Count
        if ($declared -ne $actual) {
            Add-ValidationError "分类 $categoryId 数量不一致: $indexPath 声明 $declared，实际 $actual"
        }
    }
}

$notePaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$pdfPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($index in @(
    [pscustomobject]@{ Path = $classIndex; Rows = $classRows },
    [pscustomobject]@{ Path = $readingIndex; Rows = $readingRows }
)) {
    $base = Split-Path -Parent $index.Path
    foreach ($row in $index.Rows) {
        foreach ($target in Get-LocalMarkdownTargets $row.Line $base) {
            if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
                Add-ValidationError "失效本地链接: $($index.Path) -> $target"
                continue
            }
            switch ([System.IO.Path]::GetExtension($target).ToLowerInvariant()) {
                '.md'  { [void]$notePaths.Add($target) }
                '.pdf' { [void]$pdfPaths.Add($target) }
            }
        }
    }
}

$expectedSequence = 1..$ExpectedNoteSections
foreach ($note in $notePaths) {
    $text = Get-Content -LiteralPath $note -Raw
    $sections = @([regex]::Matches($text, '(?m)^##\s+(\d+)\.') |
        ForEach-Object { [int]$_.Groups[1].Value })
    if ($sections.Count -ne $ExpectedNoteSections -or @(Compare-Object $expectedSequence $sections).Count -gt 0) {
        Add-ValidationError "笔记章节不合格: $note；得到 [$($sections -join ',')]，预期 1-$ExpectedNoteSections"
    }
}

$pdfInfo = $null
if (-not $SkipPdfInfo) {
    $pdfInfo = Find-PdfInfo $PdfInfoPath
    if (-not $pdfInfo -and $errors.Count -eq 0) {
        $warnings.Add('未找到 pdfinfo；已执行 PDF 签名检查，但跳过页数解析。')
    }
}

$totalPages = 0
foreach ($pdf in $pdfPaths) {
    $stream = [System.IO.File]::OpenRead($pdf)
    try {
        $buffer = New-Object byte[] 5
        [void]$stream.Read($buffer, 0, 5)
    } finally {
        $stream.Dispose()
    }
    if ([System.Text.Encoding]::ASCII.GetString($buffer) -ne '%PDF-') {
        Add-ValidationError "PDF签名无效: $pdf"
        continue
    }

    if ($pdfInfo) {
        $output = & $pdfInfo $pdf 2>&1
        if ($LASTEXITCODE -ne 0) {
            Add-ValidationError "PDF无法解析: $pdf :: $($output -join ' ')"
            continue
        }
        $pageLine = $output | Where-Object { $_ -match '^Pages:' } | Select-Object -First 1
        if (-not $pageLine) {
            Add-ValidationError "pdfinfo未返回页数: $pdf"
            continue
        }
        $pages = [int](($pageLine -split ':', 2)[1].Trim())
        if ($pages -lt 1) {
            Add-ValidationError "PDF页数无效: $pdf"
        } else {
            $totalPages += $pages
        }
    }
}

$yearText = Get-Content -LiteralPath $yearList -Raw
foreach ($stalePhrase in @('尚未纳入本地已读语料库', '当前语料库之外')) {
    if ($yearText.Contains($stalePhrase)) {
        Add-ValidationError "年份清单包含过期状态描述: $stalePhrase"
    }
}

foreach ($warning in $warnings) {
    Write-Host "WARNING: $warning" -ForegroundColor Yellow
}

if ($errors.Count -gt 0) {
    foreach ($message in $errors) {
        Write-Host "ERROR: $message" -ForegroundColor Red
    }
    Write-Host "FAIL errors=$($errors.Count); class_rows=$($classRows.Count); reading_rows=$($readingRows.Count); notes=$($notePaths.Count); pdfs=$($pdfPaths.Count)"
    exit 1
}

$pageSummary = if ($pdfInfo) { "; pages=$totalPages" } else { '' }
Write-Host "PASS class_rows=$($classRows.Count); reading_rows=$($readingRows.Count); notes=$($notePaths.Count); pdfs=$($pdfPaths.Count)$pageSummary"
exit 0
