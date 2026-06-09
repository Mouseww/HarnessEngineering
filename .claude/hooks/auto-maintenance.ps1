param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "../..")).Path
$targetRoot = (Resolve-Path -LiteralPath $Root).Path

$scripts = @(
  "scripts/update-memory-index.ps1",
  "scripts/generate-code-map.ps1",
  "scripts/review-changes.ps1",
  "scripts/update-workflow-gates.ps1"
)

foreach ($script in $scripts) {
  $path = Join-Path $repoRoot $script
  if (Test-Path -LiteralPath $path) {
    powershell -NoProfile -ExecutionPolicy Bypass -File $path -Root $targetRoot
    if ($LASTEXITCODE -ne 0) {
      throw "Auto-maintenance failed: $script"
    }
  }
}

Write-Output "auto-maintenance: OK"
