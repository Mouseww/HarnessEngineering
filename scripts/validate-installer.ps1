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

$repoRoot = (Resolve-Path ".").Path
$installer = Join-Path $repoRoot "scripts/install-harness.ps1"
Assert-True -Condition (Test-Path -LiteralPath $installer) -Message "Missing installer script."

$target = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-install-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $target | Out-Null

Set-Content -LiteralPath (Join-Path $target "CLAUDE.md") -Encoding UTF8 -Value "# Existing Claude Guide`n`nKeep this project-specific instruction."

powershell -NoProfile -ExecutionPolicy Bypass -File $installer -SourceRoot $repoRoot -Target $target -SkipDoctor

$expectedPaths = @(
  "harness.yaml",
  "AGENTS.md",
  "CLAUDE.md",
  ".claude/settings.json",
  ".claude/hooks/workflow-guidance.ps1",
  ".claude/skills/route-request/SKILL.md",
  ".mcp.json",
  "scripts/doctor.ps1",
  "scripts/route-request.ps1",
  "scripts/validate-english.ps1",
  "protocols/context-loading.md",
  "flows/feature-development.md",
  "mcp/harness-server/server.js",
  "work/active/.gitkeep",
  "memory/index.yaml",
  "wiki/index.md"
)

foreach ($relative in $expectedPaths) {
  Assert-True -Condition (Test-Path -LiteralPath (Join-Path $target $relative)) -Message "Installer did not create $relative."
}

$claudeText = Get-Content -LiteralPath (Join-Path $target "CLAUDE.md") -Raw
Assert-True -Condition ($claudeText -like "*Keep this project-specific instruction.*") -Message "Installer overwrote existing CLAUDE.md content."
Assert-True -Condition ($claudeText -like "*BEGIN HARNESS ENGINEERING*") -Message "Installer did not append Harness block to CLAUDE.md."

$mcp = Get-Content -LiteralPath (Join-Path $target ".mcp.json") -Raw | ConvertFrom-Json
Assert-True -Condition ($null -ne $mcp.mcpServers.harness) -Message "Installer did not register harness MCP server."

$settings = Get-Content -LiteralPath (Join-Path $target ".claude/settings.json") -Raw | ConvertFrom-Json
Assert-True -Condition ($settings.hooks.UserPromptSubmit.Count -ge 1) -Message "Installer did not merge UserPromptSubmit hook."
Assert-True -Condition (($settings.permissions.deny -join "`n") -like "*git push*") -Message "Installer did not merge dangerous operation deny rules."

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $target "scripts/validate-english.ps1")
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $target "scripts/validate-skills.ps1")

Write-Output "validate-installer: OK"
