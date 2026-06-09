$ErrorActionPreference = "Stop"

$index = Get-Content -LiteralPath "memory/index.yaml" -Raw
foreach ($needle in @("team:", "project:", "agents:", "claude-code:", "codex:")) {
  if ($index -notlike "*$needle*") {
    throw "Memory index marker missing: $needle"
  }
}

foreach ($path in @("memory/team/index.md", "memory/project/index.md", "memory/agents/claude-code/index.md", "memory/agents/codex/index.md")) {
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Memory file missing: $path"
  }
}

Write-Output "validate-memory: OK"

