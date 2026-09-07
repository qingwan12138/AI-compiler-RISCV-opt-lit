$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
py -3 "$repo/scripts/validate_innovation_evidence.py" --repo "$repo"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
