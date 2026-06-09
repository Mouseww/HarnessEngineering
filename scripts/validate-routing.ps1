$ErrorActionPreference = "Stop"

$registry = Get-Content -LiteralPath "agents/registry.yaml" -Raw
$harness = Get-Content -LiteralPath "harness.yaml" -Raw

foreach ($needle in @("primary_runtime: claude-code", "agent_registry: `"agents/registry.yaml`"", "claude-code:", "codex:")) {
  if (($harness + "`n" + $registry) -notlike "*$needle*") {
    throw "Routing marker missing: $needle"
  }
}

$mappedPaths = @(
  "CLAUDE.md",
  ".claude/settings.json",
  ".claude/skills",
  ".claude/agents",
  ".mcp.json",
  "AGENTS.md",
  "agents/codex/manifest.yaml"
)

foreach ($item in $mappedPaths) {
  if (-not (Test-Path -LiteralPath $item)) {
    throw "Mapped path missing: $item"
  }
}

Write-Output "validate-routing: OK"

