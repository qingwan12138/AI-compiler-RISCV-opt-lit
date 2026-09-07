$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$output = & py -3 "$repo/scripts/validate_innovation_evidence.py" --repo "$repo" 2>&1
$output | Write-Output
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (($output -join "`n") -notmatch 'neighbor_audits=5; mechanism_gates=5') {
    throw 'innovation evidence validator did not report all five nearest-work audits and mechanism gates'
}
