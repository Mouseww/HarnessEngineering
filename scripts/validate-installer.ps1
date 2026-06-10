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

function Invoke-CheckedPowerShell {
  param(
    [Parameter(Mandatory = $true)][string]$WorkingDirectory,
    [Parameter(Mandatory = $true)][string[]]$Arguments
  )

  Push-Location -LiteralPath $WorkingDirectory
  try {
    & powershell -NoProfile -ExecutionPolicy Bypass @Arguments
    if ($LASTEXITCODE -ne 0) {
      throw "PowerShell command failed with exit code $LASTEXITCODE in $WorkingDirectory."
    }
  } finally {
    Pop-Location
  }
}

function Copy-HarnessProbeSource {
  param(
    [Parameter(Mandatory = $true)][string]$SourceRoot,
    [Parameter(Mandatory = $true)][string]$Destination
  )

  $items = @(
    ".claude",
    "agents",
    "core",
    "flows",
    "mcp",
    "protocols",
    "scripts",
    "wiki",
    ".mcp.json",
    "harness.yaml"
  )

  foreach ($item in $items) {
    $sourcePath = Join-Path $SourceRoot $item
    $destinationPath = Join-Path $Destination $item
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destinationPath) | Out-Null
    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Recurse -Force
  }
}

$repoRoot = (Resolve-Path ".").Path
$installer = Join-Path $repoRoot "scripts/install-harness.ps1"
Assert-True -Condition (Test-Path -LiteralPath $installer) -Message "Missing installer script."

$target = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-install-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $target | Out-Null

Set-Content -LiteralPath (Join-Path $target "CLAUDE.md") -Encoding UTF8 -Value "# Existing Claude Guide`n`nKeep this project-specific instruction."

$legacySkill = Join-Path $target ".claude/skills/documentation-workflow"
New-Item -ItemType Directory -Force -Path $legacySkill | Out-Null
Set-Content -LiteralPath (Join-Path $legacySkill "SKILL.md") -Encoding UTF8 -Value @'
---
name: documentation-workflow
summary: Existing project skill with non-Harness metadata.
---

# Documentation Workflow
'@

$legacyAgent = Join-Path $target ".claude/agents/project-doc-writer.md"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $legacyAgent) | Out-Null
Set-Content -LiteralPath $legacyAgent -Encoding UTF8 -Value @'
---
name: project-doc-writer
summary: Existing project subagent with non-Harness metadata.
---

# Project Doc Writer
'@

Invoke-CheckedPowerShell -WorkingDirectory $target -Arguments @("-File", $installer, "-SourceRoot", $repoRoot, "-Target", ".", "-SkipDoctor")

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

Assert-True -Condition (Test-Path -LiteralPath (Join-Path $legacySkill "SKILL.md")) -Message "Installer removed an existing project skill."
Assert-True -Condition (Test-Path -LiteralPath $legacyAgent) -Message "Installer removed an existing project subagent."

Invoke-CheckedPowerShell -WorkingDirectory $target -Arguments @("-File", "scripts/validate-claude-code.ps1")
Invoke-CheckedPowerShell -WorkingDirectory $target -Arguments @("-File", "scripts/validate-english.ps1")
Invoke-CheckedPowerShell -WorkingDirectory $target -Arguments @("-File", "scripts/validate-skills.ps1")

$mixedSource = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-mixed-source-" + [Guid]::NewGuid().ToString("N"))
$mixedTarget = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-mixed-target-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $mixedSource, (Join-Path $mixedTarget ".claude/skills/documentation-workflow") | Out-Null
Copy-HarnessProbeSource -SourceRoot $repoRoot -Destination $mixedSource
New-Item -ItemType Directory -Force -Path (Join-Path $mixedSource ".claude/skills/documentation-workflow") | Out-Null
Set-Content -LiteralPath (Join-Path $mixedSource ".claude/skills/documentation-workflow/SKILL.md") -Encoding UTF8 -Value "source project skill"
Set-Content -LiteralPath (Join-Path $mixedTarget ".claude/skills/documentation-workflow/SKILL.md") -Encoding UTF8 -Value "target project skill"

Invoke-CheckedPowerShell -WorkingDirectory $mixedTarget -Arguments @("-File", $installer, "-SourceRoot", $mixedSource, "-Target", ".", "-SkipDoctor")
$mixedSkillText = Get-Content -LiteralPath (Join-Path $mixedTarget ".claude/skills/documentation-workflow/SKILL.md") -Raw
Assert-True -Condition ($mixedSkillText -like "*target project skill*") -Message "Installer did not preserve the target project skill."
Assert-True -Condition ($mixedSkillText -notlike "*source project skill*") -Message "Installer copied a non-Harness source skill into the target project."

$probeSource = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-source-probe-" + [Guid]::NewGuid().ToString("N"))
$probeTarget = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-target-probe-" + [Guid]::NewGuid().ToString("N"))
$probeWorkingDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-working-probe-" + [Guid]::NewGuid().ToString("N"))
$probeFile = "doctor-cwd-" + [Guid]::NewGuid().ToString("N") + ".txt"
New-Item -ItemType Directory -Force -Path $probeSource, $probeTarget, $probeWorkingDirectory | Out-Null
Copy-HarnessProbeSource -SourceRoot $repoRoot -Destination $probeSource
Set-Content -LiteralPath (Join-Path $probeSource "scripts/doctor.ps1") -Encoding UTF8 -Value @"
`$ErrorActionPreference = "Stop"
Set-Content -LiteralPath "$probeFile" -Encoding UTF8 -Value (Get-Location).Path
Write-Output "doctor: OK"
"@

Invoke-CheckedPowerShell -WorkingDirectory $probeWorkingDirectory -Arguments @("-File", $installer, "-SourceRoot", $probeSource, "-Target", $probeTarget)
Assert-True -Condition (Test-Path -LiteralPath (Join-Path $probeTarget $probeFile)) -Message "Installer doctor did not run from the target root."

Write-Output "validate-installer: OK"
