$ErrorActionPreference = "Stop"

$root = (Get-Location).Path
$files = @(
  "harness.yaml",
  "agents/registry.yaml",
  "protocols/agent-context-routing.md",
  "protocols/context-loading.md",
  "protocols/risk-confirmation.md",
  "protocols/delivery-contract.md"
)

Write-Output "Harness Engineering context:"
foreach ($file in $files) {
  $path = Join-Path $root $file
  if (Test-Path -LiteralPath $path) {
    Write-Output "- $file"
  }
}

