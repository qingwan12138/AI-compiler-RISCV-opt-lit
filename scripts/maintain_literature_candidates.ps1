[CmdletBinding()]
param(
    [ValidateSet('Report', 'ProbePdf', 'RecordCandidate')]
    [string]$Mode = 'Report',
    [string]$Root,
    [string]$CachePath,
    [string]$RunId,
    [string]$Title,
    [string]$Doi,
    [string]$ArxivId,
    [string]$Status,
    [string]$Reason,
    [string]$PdfUrl,
    [string]$PdfPath,
    [string]$PdfInfoPath
)

function Normalize-LiteratureTitle([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
    return (($Value.ToLowerInvariant() -replace '[^\p{L}\p{N}]+', ' ').Trim() -replace '\s+', ' ')
}

function Get-CandidateKey([hashtable]$Candidate) {
    $keys = [System.Collections.Generic.List[string]]::new()
    if (-not [string]::IsNullOrWhiteSpace([string]$Candidate.doi)) { $keys.Add("doi:$(([string]$Candidate.doi).Trim().ToLowerInvariant())") }
    if (-not [string]::IsNullOrWhiteSpace([string]$Candidate.arxiv_id)) { $keys.Add("arxiv:$(([string]$Candidate.arxiv_id).Trim().ToLowerInvariant())") }
    $normalized = if ($Candidate.ContainsKey('normalized_title')) { [string]$Candidate.normalized_title } else { Normalize-LiteratureTitle ([string]$Candidate.title) }
    if (-not [string]::IsNullOrWhiteSpace($normalized)) { $keys.Add("title:$normalized") }
    return @($keys)
}

function Test-CandidateRecord([hashtable]$Candidate) {
    $allowedStatuses = @('metadata_verified', 'duplicate', 'year_mismatch', 'download_failed', 'pdf_invalid', 'needs_user_session_download')
    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($name in $Candidate.Keys) {
        if ($name -match '(?i)cookie|token|password') { $errors.Add("缓存记录不得包含敏感凭据字段: $name") }
    }
    foreach ($required in @('run_id', 'checked_at', 'title', 'normalized_title', 'status')) {
        if (-not $Candidate.ContainsKey($required) -or [string]::IsNullOrWhiteSpace([string]$Candidate[$required])) { $errors.Add("缓存记录缺少必填字段: $required") }
    }
    if ($Candidate.ContainsKey('status') -and $allowedStatuses -notcontains [string]$Candidate.status) { $errors.Add("缓存记录状态不允许: $($Candidate.status)") }
    return @($errors)
}

function Get-CorpusCandidateKeys([string]$CorpusRoot) {
    $keys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($relative in @('00_分类索引.md', '文献逐篇阅读/00_逐篇阅读目录.md')) {
        $path = Join-Path $CorpusRoot $relative
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $text = Get-Content -LiteralPath $path -Raw
        foreach ($title in [regex]::Matches($text, '\[([^\]]+)\]\(')) { [void]$keys.Add("title:$(Normalize-LiteratureTitle $title.Groups[1].Value)") }
        foreach ($doi in [regex]::Matches($text, '(?i)10\.\d{4,9}/[-._;()/:a-z0-9]+')) { [void]$keys.Add("doi:$($doi.Value.ToLowerInvariant())") }
        foreach ($arxiv in [regex]::Matches($text, '(?i)(?:arXiv:|arxiv\.org/abs/)(\d{4}\.\d{4,5})')) { [void]$keys.Add("arxiv:$($arxiv.Groups[1].Value.ToLowerInvariant())") }
    }
    return $keys
}

function Get-CacheCandidateRecords([string]$Path) {
    $records = [System.Collections.Generic.List[hashtable]]::new()
    $invalidLines = [System.Collections.Generic.List[int]]::new()
    if (-not (Test-Path -LiteralPath $Path)) { return [pscustomobject]@{ Records=@(); InvalidLines=@() } }
    $lineNumber = 0
    foreach ($line in Get-Content -LiteralPath $Path) {
        $lineNumber++
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $object = ConvertFrom-Json $line -ErrorAction Stop
            $record = @{}
            foreach ($property in $object.psobject.Properties) { $record[$property.Name] = $property.Value }
            $records.Add($record)
        } catch { $invalidLines.Add($lineNumber) }
    }
    return [pscustomobject]@{ Records=@($records); InvalidLines=@($invalidLines) }
}

function New-CandidateReport([string]$CorpusRoot, [string]$Path) {
    $cache = Get-CacheCandidateRecords $Path
    $corpusKeys = Get-CorpusCandidateKeys $CorpusRoot
    $existing = 0; $failure = 0; $retryable = 0
    foreach ($record in $cache.Records) {
        if (@(Get-CandidateKey $record | Where-Object { $corpusKeys.Contains($_) }).Count -gt 0) { $existing++; continue }
        if ([string]$record.status -in @('download_failed', 'pdf_invalid', 'needs_user_session_download')) { $retryable++ } else { $failure++ }
    }
    return [pscustomobject]@{ existing_index_match=$existing; cached_failure=$failure; retryable=$retryable; invalid_cache_lines=@($cache.InvalidLines); cache_records=@($cache.Records).Count }
}

function Find-CorpusPdfInfo([string]$ExplicitPath) {
    if ($ExplicitPath -and (Test-Path -LiteralPath $ExplicitPath)) { return (Resolve-Path -LiteralPath $ExplicitPath).Path }
    $command = Get-Command pdfinfo.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    $runtimeRoot = Join-Path $HOME '.cache/codex-runtimes'
    if (Test-Path -LiteralPath $runtimeRoot) {
        return Get-ChildItem -LiteralPath $runtimeRoot -Recurse -Filter pdfinfo.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    }
    return $null
}

function Test-PdfCandidate {
    [CmdletBinding()]
    param([string]$PdfPath, [string]$PdfUrl, [string]$PdfInfoPath)
    $temporary = $false
    $finalUrl = $PdfUrl
    try {
        if ($PdfUrl) {
            $PdfPath = Join-Path ([System.IO.Path]::GetTempPath()) ("literature-probe-$([guid]::NewGuid().ToString('N')).bin")
            $response = Invoke-WebRequest -Uri $PdfUrl -OutFile $PdfPath -MaximumRedirection 8 -ErrorAction Stop
            $temporary = $true
            if ($response.BaseResponse.ResponseUri) { $finalUrl = $response.BaseResponse.ResponseUri.AbsoluteUri }
        }
        if (-not $PdfPath -or -not (Test-Path -LiteralPath $PdfPath -PathType Leaf)) { return [pscustomobject]@{ IsPdf=$false; Pages=0; FailureKind='missing_file'; FinalUrl=$finalUrl } }
        $stream = [System.IO.File]::OpenRead($PdfPath)
        try { $buffer = New-Object byte[] 5; [void]$stream.Read($buffer, 0, 5) } finally { $stream.Dispose() }
        if ([System.Text.Encoding]::ASCII.GetString($buffer) -ne '%PDF-') { return [pscustomobject]@{ IsPdf=$false; Pages=0; FailureKind='html_response'; FinalUrl=$finalUrl } }
        $pdfInfo = Find-CorpusPdfInfo $PdfInfoPath
        if (-not $pdfInfo) { return [pscustomobject]@{ IsPdf=$true; Pages=0; FailureKind='pdfinfo_unavailable'; FinalUrl=$finalUrl } }
        $output = & $pdfInfo $PdfPath 2>&1
        $pageLine = $output | Where-Object { $_ -match '^Pages:' } | Select-Object -First 1
        if ($LASTEXITCODE -ne 0 -or -not $pageLine) { return [pscustomobject]@{ IsPdf=$false; Pages=0; FailureKind='unparseable_pdf'; FinalUrl=$finalUrl } }
        $pages = [int](($pageLine -split ':', 2)[1].Trim())
        return [pscustomobject]@{ IsPdf=($pages -gt 0); Pages=$pages; FailureKind=if($pages -gt 0){$null}else{'unparseable_pdf'}; FinalUrl=$finalUrl }
    } catch {
        return [pscustomobject]@{ IsPdf=$false; Pages=0; FailureKind='network_error'; FinalUrl=$finalUrl }
    } finally {
        if ($temporary -and $PdfPath -and (Test-Path -LiteralPath $PdfPath)) { Remove-Item -LiteralPath $PdfPath -Force }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    switch ($Mode) {
        'RecordCandidate' {
            if (-not $CachePath) { throw 'RecordCandidate 模式需要 -CachePath' }
            $record = @{ run_id=$RunId; checked_at=(Get-Date).ToUniversalTime().ToString('o'); title=$Title; normalized_title=(Normalize-LiteratureTitle $Title); doi=$Doi; arxiv_id=$ArxivId; status=$Status; reason=$Reason }
            $errors = Test-CandidateRecord $record
            if ($errors.Count -gt 0) { throw ($errors -join '; ') }
            $parent = Split-Path -Parent $CachePath
            if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            Add-Content -LiteralPath $CachePath -Value ($record | ConvertTo-Json -Compress) -Encoding utf8
            [pscustomobject]$record
        }
        'Report' {
            if (-not $Root -or -not $CachePath) { throw 'Report 模式需要 -Root 和 -CachePath' }
            New-CandidateReport -CorpusRoot $Root -Path $CachePath
        }
        'ProbePdf' { Test-PdfCandidate -PdfPath $PdfPath -PdfUrl $PdfUrl -PdfInfoPath $PdfInfoPath }
    }
}
