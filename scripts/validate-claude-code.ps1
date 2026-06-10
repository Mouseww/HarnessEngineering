$ErrorActionPreference = "Stop"

function Assert-Frontmatter {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Kind
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Missing Claude Code Harness ${Kind}: $Name"
  }

  $content = Get-Content -LiteralPath $Path -Raw
  $escapedName = [regex]::Escape($Name)
  if ($content -notmatch "(?s)^---\s*.*name:\s*$escapedName\s*.*description:\s*Use when .+?---") {
    throw "Invalid Harness $Kind frontmatter: $Path"
  }
}

Get-Content -LiteralPath ".claude/settings.json" -Raw | ConvertFrom-Json | Out-Null

$skillsRoot = ".claude/skills"
if (-not (Test-Path -LiteralPath $skillsRoot)) {
  throw "Missing Claude Code skills directory."
}

$requiredSkills = @(
  "discover-context",
  "route-request",
  "shape-design",
  "write-implementation-plan",
  "execute-plan",
  "diagnose-failure",
  "prove-behavior-first",
  "implement-safely",
  "verify-before-delivery",
  "review-changes",
  "request-review",
  "handle-review-feedback",
  "release-readiness",
  "capture-memory",
  "mcp-governance",
  "plan-work"
)

foreach ($skill in $requiredSkills) {
  Assert-Frontmatter -Path (Join-Path $skillsRoot "$skill/SKILL.md") -Name $skill -Kind "skill"
}

$agentsRoot = ".claude/agents"
if (-not (Test-Path -LiteralPath $agentsRoot)) {
  throw "Missing Claude Code subagents directory."
}

$requiredAgents = @(
  "architect",
  "implementer",
  "mcp-curator",
  "memory-curator",
  "release-manager",
  "reviewer",
  "tester"
)

foreach ($agent in $requiredAgents) {
  Assert-Frontmatter -Path (Join-Path $agentsRoot "$agent.md") -Name $agent -Kind "subagent"
}

Write-Output "validate-claude-code: OK"
