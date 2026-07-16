[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Root,

    [ValidateRange(1, 99)]
    [int]$ExpectedNoteSections = 14,

    [string]$PdfInfoPath,

    [switch]$SkipPdfInfo
)

$validator = Join-Path $PSScriptRoot '../skills/maintaining-compiler-literature-corpus/scripts/validate_literature_corpus.ps1'
& $validator @PSBoundParameters
exit $LASTEXITCODE
