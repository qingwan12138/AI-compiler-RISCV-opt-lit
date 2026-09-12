param(
    [switch]$Doctor,
    [switch]$Quick,
    [string]$Platform = "x86_local_gcc",
    [string]$Contract = "runtime_efficiency",
    [int]$Repeats = 5,
    [int]$Warmups = 1,
    [int]$Size = 1000000,
    [double]$Timeout = 60.0
)

$ErrorActionPreference = "Stop"
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$PythonLauncher = Get-Command py -ErrorAction SilentlyContinue

if ($null -eq $PythonLauncher) {
    throw "Python launcher 'py' was not found. Install Python 3 and retry."
}

$Program = Join-Path $ScriptDirectory "epas_demo.py"

if ($Doctor) {
    & $PythonLauncher.Path $Program doctor --platform $Platform
    exit $LASTEXITCODE
}

if ($Quick) {
    $Size = 200000
    $Repeats = 2
    $Warmups = 1
}

$CommandArguments = @(
    $Program,
    "run",
    "--platform", $Platform,
    "--contract", $Contract,
    "--repeats", $Repeats,
    "--warmups", $Warmups,
    "--size", $Size,
    "--timeout", $Timeout
)

& $PythonLauncher.Path @CommandArguments
exit $LASTEXITCODE
