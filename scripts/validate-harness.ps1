$ErrorActionPreference = "Stop"

$root = (Resolve-Path ".").Path
$required = @(
  "README.md",
  "CLAUDE.md",
  "AGENTS.md",
  "harness.yaml",
  "agents/registry.yaml",
  ".claude/settings.json",
  ".claude/skills",
  ".claude/agents",
  ".mcp.json",
  "protocols/agent-context-routing.md",
  "protocols/context-loading.md",
  "protocols/risk-confirmation.md",
  "protocols/delivery-contract.md",
  "scripts/harness.ps1",
  "mcp/harness-server/server.js",
  "mcp/catalog.yaml",
  "wiki/index.md",
  "memory/index.yaml",
  "work/brainstorms",
  "work/designs",
  "work/plans",
  "scripts/validate-workflow-capabilities.ps1",
  "scripts/validate-flow-router.ps1",
  "scripts/route-request.ps1",
  ".claude/hooks/workflow-guidance.ps1",
  "scripts/update-workflow-gates.ps1",
  "work/request-routing"
)

$missing = @()
foreach ($item in $required) {
  $path = Join-Path $root $item
  if (-not (Test-Path -LiteralPath $path)) {
    $missing += $item
  }
}

if ($missing.Count -gt 0) {
  throw "Missing required Harness paths: $($missing -join ', ')"
}

Get-Content -LiteralPath ".claude/settings.json" -Raw | ConvertFrom-Json | Out-Null
Get-Content -LiteralPath ".mcp.json" -Raw | ConvertFrom-Json | Out-Null

Write-Output "validate-harness: OK"
