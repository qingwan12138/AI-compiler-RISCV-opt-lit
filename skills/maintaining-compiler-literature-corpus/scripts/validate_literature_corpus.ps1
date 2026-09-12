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
        if ($line -notmatch '^\|\s*([A-Za-z]+\d+|\d+)\s*\|') { continue }
        $cells = @($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
        if ($cells.Count -lt 5) { continue }
        $rows.Add([pscustomobject]@{
            Id = $cells[0]
            Year = $cells[1]
            Category = $cells[2]
            Line = $line
        })
    }
    return @($rows)
}

function Get-LocalLinkTargets([string]$Line, [string]$BaseDirectory) {
    $targets = [System.Collections.Generic.List[object]]::new()
    foreach ($match in [regex]::Matches($Line, '\]\((<[^>]+>|[^)\s]+)\)')) {
        $raw = $match.Groups[1].Value.Trim('<', '>')
        if ($raw -match '^(https?|mailto|tel|data):' -or $raw.StartsWith('#')) { continue }
        $pathPart = ($raw -split '#', 2)[0]
        if ([string]::IsNullOrWhiteSpace($pathPart)) { continue }
        $decoded = [System.Uri]::UnescapeDataString($pathPart)
        $fullPath = [System.IO.Path]::GetFullPath((Join-Path $BaseDirectory $decoded))
        $targets.Add([pscustomobject]@{
            Path = $fullPath
            Extension = [System.IO.Path]::GetExtension($fullPath).ToLowerInvariant()
            Raw = $raw
        })
    }
    return @($targets)
}

function Get-ExpectedTarget([string]$RelativePath, [string]$BaseDirectory) {
    return [System.IO.Path]::GetFullPath((Join-Path $BaseDirectory $RelativePath))
}

function Test-IndexMatchesTaxonomy([string]$Path, [object[]]$Rows, [string]$BaseDirectory, [bool]$CheckCategory, [hashtable]$TaxonomyById) {
    foreach ($row in $Rows) {
        if (-not $TaxonomyById.ContainsKey($row.Id)) {
            Add-ValidationError "索引编号不在 taxonomy_v2.csv 中: $($row.Id) :: $Path"
            continue
        }
        $taxon = $TaxonomyById[$row.Id]
        if ($CheckCategory) {
            $expectedCategory = "$($taxon.Primary_Category) / $($taxon.Secondary_Category)"
            if ($row.Category -ne $expectedCategory) {
                Add-ValidationError "角色索引分类与 taxonomy 不一致: $($row.Id)，索引 '$($row.Category)'，CSV '$expectedCategory'"
            }
        }

        $targets = @(Get-LocalLinkTargets $row.Line $BaseDirectory)
        $notes = @($targets | Where-Object { $_.Extension -eq '.md' })
        $pdfs = @($targets | Where-Object { $_.Extension -eq '.pdf' })
        $expectedNote = Get-ExpectedTarget $taxon.Note_Path $script:rootPath
        if ($notes.Count -ne 1 -or $notes[0].Path -ne $expectedNote) {
            Add-ValidationError "笔记链接未匹配 Note_Path: $($row.Id) :: $Path"
        }

        if ($taxon.PDF_Path -eq 'SOURCE_LIMITED_NO_LOCAL_PDF') {
            if ($pdfs.Count -gt 0) {
                Add-ValidationError "源材料受限条目存在本地 PDF 链接: $($row.Id) :: $Path"
            }
        } else {
            $expectedPdf = Get-ExpectedTarget $taxon.PDF_Path $script:rootPath
            if ($pdfs.Count -ne 1 -or $pdfs[0].Path -ne $expectedPdf) {
                Add-ValidationError "PDF 链接未匹配 PDF_Path: $($row.Id) :: $Path"
            }
        }

        foreach ($target in $targets) {
            if (-not (Test-Path -LiteralPath $target.Path -PathType Leaf)) {
                Add-ValidationError "失效本地索引链接: $Path -> $($target.Raw)"
            }
        }
    }
}

function Find-PdfInfo([string]$ExplicitPath) {
    if ($ExplicitPath) {
        if (Test-Path -LiteralPath $ExplicitPath) { return (Resolve-Path -LiteralPath $ExplicitPath).Path }
        Add-ValidationError "指定的 pdfinfo 不存在: $ExplicitPath"
        return $null
    }
    $command = Get-Command pdfinfo.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    $runtimeRoot = Join-Path $HOME '.cache/codex-runtimes'
    if (Test-Path -LiteralPath $runtimeRoot) {
        return Get-ChildItem -LiteralPath $runtimeRoot -Recurse -Filter 'pdfinfo.exe' -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
    }
    return $null
}

try {
    $script:rootPath = (Resolve-Path -LiteralPath $Root).Path
} catch {
    Write-Error "语料库根目录不存在: $Root"
    exit 1
}

$taxonomyPath = Join-Path $rootPath 'taxonomy_v2.csv'
$classIndex = Join-Path $rootPath '00_三大类分类索引_v2.md'
$readingIndex = Join-Path $rootPath '文献逐篇阅读/00_逐篇阅读目录.md'
$yearList = Join-Path $rootPath '文献逐篇阅读/2024-2026_文献年份筛选清单.md'
$requiredFiles = @($taxonomyPath, $classIndex, $readingIndex, $yearList)
foreach ($file in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { Add-ValidationError "缺少必需文件: $file" }
}
if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Host "ERROR: $_" -ForegroundColor Red }
    exit 1
}

$taxonomyRows = @(Import-Csv -LiteralPath $taxonomyPath)
if ($taxonomyRows.Count -eq 0) { Add-ValidationError 'taxonomy_v2.csv 没有数据行' }
$taxonomyFields = @($taxonomyRows[0].PSObject.Properties.Name)
foreach ($field in @('Paper_ID', 'Primary_Category', 'Secondary_Category', 'PDF_Path', 'Note_Path')) {
    if ($taxonomyFields -notcontains $field) { Add-ValidationError "taxonomy_v2.csv 缺少当前字段: $field" }
}

$taxonomyById = @{}
foreach ($row in $taxonomyRows) {
    if ([string]::IsNullOrWhiteSpace($row.Paper_ID)) {
        Add-ValidationError 'taxonomy_v2.csv 存在空 Paper_ID'
        continue
    }
    if ($taxonomyById.ContainsKey($row.Paper_ID)) {
        Add-ValidationError "taxonomy_v2.csv Paper_ID 重复: $($row.Paper_ID)"
        continue
    }
    $taxonomyById[$row.Paper_ID] = $row
}

$classRows = @(Get-IndexRows $classIndex)
$readingRows = @(Get-IndexRows $readingIndex)
foreach ($index in @(
    [pscustomobject]@{ Path = $classIndex; Rows = $classRows },
    [pscustomobject]@{ Path = $readingIndex; Rows = $readingRows }
)) {
    $ids = @($index.Rows.Id)
    $uniqueIds = @($ids | Sort-Object -Unique)
    if ($ids.Count -ne $uniqueIds.Count) { Add-ValidationError "索引存在重复 Paper_ID: $($index.Path)" }
    $difference = @(Compare-Object -ReferenceObject @($taxonomyById.Keys | Sort-Object) -DifferenceObject @($uniqueIds | Sort-Object))
    if ($difference.Count -gt 0) {
        $detail = ($difference | ForEach-Object { "$($_.InputObject)[$($_.SideIndicator)]" }) -join ', '
        Add-ValidationError "taxonomy 与索引编号集合不一致: $($index.Path) :: $detail"
    }
}

Test-IndexMatchesTaxonomy $classIndex $classRows $rootPath $true $taxonomyById
$readingBase = Split-Path -Parent $readingIndex
Test-IndexMatchesTaxonomy $readingIndex $readingRows $readingBase $false $taxonomyById

$roleDistribution = @{}
foreach ($category in @('SELECTOR', 'TRANSLATOR', 'GENERATOR', 'SUPPORTING')) {
    $roleDistribution[$category] = @($taxonomyRows | Where-Object { $_.Primary_Category -eq $category }).Count
}
$classText = Get-Content -LiteralPath $classIndex -Raw
if ($classText -notmatch '条目总数[：:]\s*\*\*(\d+)\*\*' -or [int]$Matches[1] -ne $taxonomyRows.Count) {
    Add-ValidationError '角色索引条目总数与 taxonomy_v2.csv 不一致'
}
foreach ($category in $roleDistribution.Keys) {
    if ($classText -notmatch "$category[：:]\s*\*\*(\d+)\*\*" -or [int]$Matches[1] -ne $roleDistribution[$category]) {
        Add-ValidationError "角色索引 $category 数量与 taxonomy_v2.csv 不一致"
    }
}

$notePaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$pdfPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($row in $taxonomyRows) {
    $note = Get-ExpectedTarget $row.Note_Path $rootPath
    if (-not (Test-Path -LiteralPath $note -PathType Leaf)) {
        Add-ValidationError "Note_Path 不存在: $($row.Paper_ID) :: $($row.Note_Path)"
    } else {
        [void]$notePaths.Add($note)
    }
    if ($row.PDF_Path -ne 'SOURCE_LIMITED_NO_LOCAL_PDF') {
        $pdf = Get-ExpectedTarget $row.PDF_Path $rootPath
        if (-not (Test-Path -LiteralPath $pdf -PathType Leaf)) {
            Add-ValidationError "PDF_Path 不存在: $($row.Paper_ID) :: $($row.PDF_Path)"
        } else {
            [void]$pdfPaths.Add($pdf)
        }
    }
}

$expectedSequence = 1..$ExpectedNoteSections
foreach ($note in $notePaths) {
    $text = Get-Content -LiteralPath $note -Raw
    $sections = @([regex]::Matches($text, '(?m)^##\s+(\d+)\.') | ForEach-Object { [int]$_.Groups[1].Value })
    if ($sections.Count -ne $ExpectedNoteSections -or @(Compare-Object $expectedSequence $sections).Count -gt 0) {
        Add-ValidationError "笔记章节不合格: $note；得到 [$($sections -join ',')]，预期 1-$ExpectedNoteSections"
    }
}

$pdfInfo = $null
if (-not $SkipPdfInfo) {
    $pdfInfo = Find-PdfInfo $PdfInfoPath
    if (-not $pdfInfo -and $errors.Count -eq 0) { $warnings.Add('未找到 pdfinfo；已执行 PDF 签名检查，但跳过页数解析。') }
}
$totalPages = 0
foreach ($pdf in $pdfPaths) {
    $stream = [System.IO.File]::OpenRead($pdf)
    try { $buffer = New-Object byte[] 5; [void]$stream.Read($buffer, 0, 5) } finally { $stream.Dispose() }
    if ([System.Text.Encoding]::ASCII.GetString($buffer) -ne '%PDF-') {
        Add-ValidationError "PDF 签名无效: $pdf"
        continue
    }
    if ($pdfInfo) {
        $output = & $pdfInfo $pdf 2>&1
        if ($LASTEXITCODE -ne 0) { Add-ValidationError "PDF 无法解析: $pdf :: $($output -join ' ')"; continue }
        $pageLine = $output | Where-Object { $_ -match '^Pages:' } | Select-Object -First 1
        if (-not $pageLine) { Add-ValidationError "pdfinfo 未返回页数: $pdf"; continue }
        $pages = [int](($pageLine -split ':', 2)[1].Trim())
        if ($pages -lt 1) { Add-ValidationError "PDF 页数无效: $pdf" } else { $totalPages += $pages }
    }
}

$yearText = Get-Content -LiteralPath $yearList -Raw
foreach ($stalePhrase in @('尚未纳入本地已读语料库', '当前语料库之外')) {
    if ($yearText.Contains($stalePhrase)) { Add-ValidationError "年份清单包含过期状态描述: $stalePhrase" }
}

foreach ($warning in $warnings) { Write-Host "WARNING: $warning" -ForegroundColor Yellow }
if ($errors.Count -gt 0) {
    foreach ($message in $errors) { Write-Host "ERROR: $message" -ForegroundColor Red }
    Write-Host "FAIL errors=$($errors.Count); taxonomy_rows=$($taxonomyRows.Count); class_rows=$($classRows.Count); reading_rows=$($readingRows.Count); notes=$($notePaths.Count); pdfs=$($pdfPaths.Count)"
    exit 1
}
$pageSummary = if ($pdfInfo) { "; pages=$totalPages" } else { '' }
Write-Host "PASS taxonomy_rows=$($taxonomyRows.Count); class_rows=$($classRows.Count); reading_rows=$($readingRows.Count); notes=$($notePaths.Count); pdfs=$($pdfPaths.Count)$pageSummary"
exit 0
