$ErrorActionPreference = "Stop"

function Assert-True {
  param(
    [Parameter(Mandatory = $true)][bool]$Condition,
    [Parameter(Mandatory = $true)][string]$Message
  )

  if (-not $Condition) {
    throw $Message
  }
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

$requiredSections = @(
  "## Core Principle",
  "## Hard Gate",
  "## Quick Reference",
  "## Red Flags",
  "## Verification"
)

$skillsRoot = ".claude/skills"
$pressurePath = ".claude/skills/_quality/pressure-scenarios.md"
Assert-True -Condition (Test-Path -LiteralPath $pressurePath) -Message "Missing pressure scenario file."
$pressureText = Get-Content -LiteralPath $pressurePath -Raw

foreach ($skill in $requiredSkills) {
  $skillFile = Join-Path $skillsRoot "$skill/SKILL.md"
  Assert-True -Condition (Test-Path -LiteralPath $skillFile) -Message "Missing skill: $skill"
  $content = Get-Content -LiteralPath $skillFile -Raw

  Assert-True -Condition ($content -match "(?s)^---\s*.*name:\s*$skill\s*.*description:\s*Use when .+?---") -Message "Invalid frontmatter for skill: $skill"
  Assert-True -Condition ($content -notmatch "(?m)^description:.*\b(write|read|run|create|execute|invoke|dispatch|then)\b.*\b(and|then)\b") -Message "Description appears to summarize workflow instead of trigger: $skill"

  foreach ($section in $requiredSections) {
    Assert-True -Condition ($content.Contains($section)) -Message "Skill $skill missing section: $section"
  }

  Assert-True -Condition ($pressureText -like "*## $skill*") -Message "Pressure scenarios missing skill: $skill"
}

$routePrompts = @(
  "Fix login failure and add regression verification",
  "Design a new MCP tool and create implementation plan",
  "Release v1.2.0 with rollback notes",
  "Production outage all users cannot login",
  "Handle review feedback from code review"
)

foreach ($prompt in $routePrompts) {
  $routeJson = powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/route-request.ps1" -Prompt $prompt -Json -NoWrite
  $route = $routeJson | ConvertFrom-Json
  foreach ($skill in $route.skills) {
    $path = Join-Path $skillsRoot "$skill/SKILL.md"
    Assert-True -Condition (Test-Path -LiteralPath $path) -Message "Router returned missing skill '$skill' for prompt '$prompt'."
  }
}

Write-Output "validate-skills: OK"

