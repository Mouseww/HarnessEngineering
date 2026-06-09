$ErrorActionPreference = "Stop"

$scripts = @(
  "scripts/validate-harness.ps1",
  "scripts/validate-routing.ps1",
  "scripts/validate-claude-code.ps1",
  "scripts/validate-hooks.ps1",
  "scripts/validate-memory.ps1",
  "scripts/validate-mcp.ps1",
  "scripts/validate-actions.ps1",
  "scripts/validate-automation-hooks.ps1",
  "scripts/validate-workflow-capabilities.ps1",
  "scripts/validate-flow-router.ps1",
  "scripts/validate-skills.ps1",
  "scripts/validate-english.ps1",
  "scripts/validate-installer.ps1"
)

foreach ($script in $scripts) {
  powershell -NoProfile -ExecutionPolicy Bypass -File $script
  if ($LASTEXITCODE -ne 0) {
    throw "Validation failed: $script"
  }
}

Write-Output "doctor: OK"
