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

$repoRoot = (Resolve-Path ".").Path
$installerPath = Join-Path $repoRoot "scripts/install-harness.ps1"

$target = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-uninstall-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $target | Out-Null

Set-Content -LiteralPath (Join-Path $target "README.md") -Encoding UTF8 -Value "# Project README`n`nKeep project README."
Set-Content -LiteralPath (Join-Path $target "CLAUDE.md") -Encoding UTF8 -Value "# Project Claude`n`nKeep project Claude guide."
Set-Content -LiteralPath (Join-Path $target "AGENTS.md") -Encoding UTF8 -Value "# Project Agents`n`nKeep project agent guide."

New-Item -ItemType Directory -Force -Path (Join-Path $target ".claude/hooks") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $target ".claude/skills/documentation-workflow") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $target ".claude/agents") | Out-Null

Set-Content -LiteralPath (Join-Path $target ".claude/hooks/custom.ps1") -Encoding UTF8 -Value 'Write-Output "project custom hook"'
Set-Content -LiteralPath (Join-Path $target ".claude/skills/documentation-workflow/SKILL.md") -Encoding UTF8 -Value (@(
  "---",
  "name: documentation-workflow",
  "summary: Project-owned skill.",
  "---",
  "",
  "# Documentation Workflow"
) -join [Environment]::NewLine)
Set-Content -LiteralPath (Join-Path $target ".claude/agents/project-doc-writer.md") -Encoding UTF8 -Value (@(
  "---",
  "name: project-doc-writer",
  "summary: Project-owned subagent.",
  "---",
  "",
  "# Project Doc Writer"
) -join [Environment]::NewLine)

$settings = [ordered]@{
  permissions = [ordered]@{
    deny = @("Bash(project-custom-deny:*)")
  }
  hooks = [ordered]@{
    UserPromptSubmit = @(
      [ordered]@{
        matcher = "project-custom"
        hooks = @(
          [ordered]@{
            type = "command"
            command = 'powershell -NoProfile -ExecutionPolicy Bypass -File ".claude/hooks/custom.ps1"'
          }
        )
      }
    )
  }
}
$settings | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath (Join-Path $target ".claude/settings.json") -Encoding UTF8

$mcp = [ordered]@{
  mcpServers = [ordered]@{
    project = [ordered]@{
      command = "node"
      args = @("project-mcp/server.js")
    }
  }
}
$mcp | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $target ".mcp.json") -Encoding UTF8

Invoke-CheckedPowerShell -WorkingDirectory $target -Arguments @("-File", $installerPath, "-SourceRoot", $repoRoot, "-Target", ".", "-SkipDoctor")

Assert-True -Condition (Test-Path -LiteralPath (Join-Path $target ".harness/scripts/uninstall-harness.ps1")) -Message "Installer did not copy uninstaller into .harness."
Assert-True -Condition (Test-Path -LiteralPath (Join-Path $target ".claude/skills/route-request/SKILL.md")) -Message "Installer did not create root skill bridge."

Invoke-CheckedPowerShell -WorkingDirectory $target -Arguments @("-File", ".harness/scripts/uninstall-harness.ps1")

Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $target ".harness"))) -Message "Uninstaller did not remove .harness."
Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $target ".claude/skills/route-request/SKILL.md"))) -Message "Uninstaller did not remove Harness root skill bridge."
Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $target ".claude/hooks/workflow-guidance.ps1"))) -Message "Uninstaller did not remove Harness root hook bridge."
Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $target ".claude/agents/reviewer.md"))) -Message "Uninstaller did not remove Harness root subagent bridge."

$readmeText = Get-Content -LiteralPath (Join-Path $target "README.md") -Raw
$claudeText = Get-Content -LiteralPath (Join-Path $target "CLAUDE.md") -Raw
$agentsText = Get-Content -LiteralPath (Join-Path $target "AGENTS.md") -Raw
Assert-True -Condition ($readmeText -like "*Keep project README.*") -Message "Uninstaller removed project README content."
Assert-True -Condition ($claudeText -like "*Keep project Claude guide.*") -Message "Uninstaller removed project CLAUDE content."
Assert-True -Condition ($agentsText -like "*Keep project agent guide.*") -Message "Uninstaller removed project AGENTS content."
Assert-True -Condition ($readmeText -notlike "*BEGIN HARNESS ENGINEERING*") -Message "Uninstaller left Harness block in README."
Assert-True -Condition ($claudeText -notlike "*BEGIN HARNESS ENGINEERING*") -Message "Uninstaller left Harness block in CLAUDE.md."
Assert-True -Condition ($agentsText -notlike "*BEGIN HARNESS ENGINEERING*") -Message "Uninstaller left Harness block in AGENTS.md."

Assert-True -Condition (Test-Path -LiteralPath (Join-Path $target ".claude/hooks/custom.ps1")) -Message "Uninstaller removed project custom hook."
Assert-True -Condition (Test-Path -LiteralPath (Join-Path $target ".claude/skills/documentation-workflow/SKILL.md")) -Message "Uninstaller removed project skill."
Assert-True -Condition (Test-Path -LiteralPath (Join-Path $target ".claude/agents/project-doc-writer.md")) -Message "Uninstaller removed project subagent."

$remainingMcp = Get-Content -LiteralPath (Join-Path $target ".mcp.json") -Raw | ConvertFrom-Json
Assert-True -Condition ($null -ne $remainingMcp.mcpServers.project) -Message "Uninstaller removed project MCP server."
Assert-True -Condition ($null -eq $remainingMcp.mcpServers.harness) -Message "Uninstaller left Harness MCP server."

$remainingSettings = Get-Content -LiteralPath (Join-Path $target ".claude/settings.json") -Raw | ConvertFrom-Json
Assert-True -Condition (($remainingSettings.permissions.deny -join "`n") -like "*project-custom-deny*") -Message "Uninstaller removed project deny rule."
Assert-True -Condition (($remainingSettings.permissions.deny -join "`n") -notlike "*git push*") -Message "Uninstaller left Harness git deny rule."
Assert-True -Condition ((($remainingSettings.hooks.UserPromptSubmit.hooks.command) -join "`n") -like "*custom.ps1*") -Message "Uninstaller removed project hook setting."
Assert-True -Condition ((($remainingSettings.hooks.UserPromptSubmit.hooks.command) -join "`n") -notlike "*workflow-guidance.ps1*") -Message "Uninstaller left Harness hook setting."

Write-Output "validate-uninstaller: OK"
