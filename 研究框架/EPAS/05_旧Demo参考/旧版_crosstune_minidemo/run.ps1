param(
  [string]$Platform = "x86",
  [switch]$Simulate
)
$ErrorActionPreference = "Stop"
$argsList = @("crosstune_demo.py", "--platform", $Platform)
if ($Simulate) { $argsList += "--simulate" }
$python = $null
foreach ($candidate in @("py", "python", "python3")) {
  $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
  if ($cmd) {
    try {
      & $candidate --version *> $null
      if ($LASTEXITCODE -eq 0) { $python = $candidate; break }
    } catch { }
  }
}
if (-not $python) {
  throw "未找到可执行的 Python 3。请从 python.org 安装，并勾选 Add Python to PATH。"
}
& $python @argsList
