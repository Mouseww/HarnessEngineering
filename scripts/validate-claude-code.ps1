$ErrorActionPreference = "Stop"

Get-Content -LiteralPath ".claude/settings.json" -Raw | ConvertFrom-Json | Out-Null

$skills = Get-ChildItem -LiteralPath ".claude/skills" -Directory | Where-Object { $_.Name -ne "_quality" }
if ($skills.Count -lt 1) {
  throw "No Claude Code project skills found."
}

foreach ($skill in $skills) {
  $skillFile = Join-Path $skill.FullName "SKILL.md"
  if (-not (Test-Path -LiteralPath $skillFile)) {
    throw "Missing SKILL.md: $($skill.Name)"
  }
  $content = Get-Content -LiteralPath $skillFile -Raw
  if ($content -notmatch "(?s)^---\s*.*name:\s*[a-zA-Z0-9-]+.*description:\s*Use when .+?---") {
    throw "Invalid skill frontmatter: $skillFile"
  }
}

$agents = Get-ChildItem -LiteralPath ".claude/agents" -Filter "*.md"
if ($agents.Count -lt 1) {
  throw "No Claude Code subagents found."
}

foreach ($agent in $agents) {
  $content = Get-Content -LiteralPath $agent.FullName -Raw
  if ($content -notmatch "(?s)^---\s*.*name:\s*[a-zA-Z0-9-]+.*description:\s*Use when .+?---") {
    throw "Invalid subagent frontmatter: $($agent.FullName)"
  }
}

Write-Output "validate-claude-code: OK"
