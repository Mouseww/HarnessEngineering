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

function Assert-PathExists {
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$RelativePath
  )

  $path = Join-Path $Root $RelativePath
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Installer did not create $RelativePath."
  }
}

function Assert-PathMissing {
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$RelativePath
  )

  $path = Join-Path $Root $RelativePath
  if (Test-Path -LiteralPath $path) {
    throw "Installer scattered canonical runtime file at project root: $RelativePath."
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
    "README.md",
    "CLAUDE.md",
    "AGENTS.md",
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
$installerPath = Join-Path $repoRoot "scripts/install-harness.ps1"
Assert-True -Condition (Test-Path -LiteralPath $installerPath) -Message "Missing installer script."

$target = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-install-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $target | Out-Null

Set-Content -LiteralPath (Join-Path $target "CLAUDE.md") -Encoding UTF8 -Value "# Existing Claude Guide`n`nKeep this project-specific instruction."

$legacySkill = Join-Path $target ".claude/skills/documentation-workflow"
New-Item -ItemType Directory -Force -Path $legacySkill | Out-Null
Set-Content -LiteralPath (Join-Path $legacySkill "SKILL.md") -Encoding UTF8 -Value (@(
  "---",
  "name: documentation-workflow",
  "summary: Existing project skill with non-Harness metadata.",
  "---",
  "",
  "# Documentation Workflow"
) -join [Environment]::NewLine)

$legacyAgent = Join-Path $target ".claude/agents/project-doc-writer.md"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $legacyAgent) | Out-Null
Set-Content -LiteralPath $legacyAgent -Encoding UTF8 -Value (@(
  "---",
  "name: project-doc-writer",
  "summary: Existing project subagent with non-Harness metadata.",
  "---",
  "",
  "# Project Doc Writer"
) -join [Environment]::NewLine)

$nestedProjectSkill = Join-Path $target "backend/rsp.sparkhub/.github/skills/documentation-workflow"
New-Item -ItemType Directory -Force -Path $nestedProjectSkill | Out-Null
$nestedCjkHeading = "# " + [string]::Concat([char]0x6587, [char]0x6863, [char]0x5DE5, [char]0x4F5C, [char]0x6D41)
Set-Content -LiteralPath (Join-Path $nestedProjectSkill "SKILL.md") -Encoding UTF8 -Value (@(
  "---",
  "name: documentation-workflow",
  "summary: Existing nested project skill.",
  "---",
  "",
  $nestedCjkHeading
) -join [Environment]::NewLine)

Invoke-CheckedPowerShell -WorkingDirectory $target -Arguments @("-File", $installerPath, "-SourceRoot", $repoRoot, "-Target", ".", "-SkipDoctor")

$canonicalPaths = @(
  ".harness/harness.yaml",
  ".harness/agents/registry.yaml",
  ".harness/.claude/settings.json",
  ".harness/.claude/hooks/workflow-guidance.ps1",
  ".harness/.claude/skills/route-request/SKILL.md",
  ".harness/.mcp.json",
  ".harness/scripts/doctor.ps1",
  ".harness/scripts/route-request.ps1",
  ".harness/protocols/context-loading.md",
  ".harness/flows/feature-development.md",
  ".harness/mcp/harness-server/server.js",
  ".harness/work/active/.gitkeep",
  ".harness/memory/index.yaml",
  ".harness/wiki/index.md"
)

foreach ($relative in $canonicalPaths) {
  Assert-PathExists -Root $target -RelativePath $relative
}

$bridgePaths = @(
  "AGENTS.md",
  "CLAUDE.md",
  "README.md",
  ".mcp.json",
  ".claude/settings.json",
  ".claude/hooks/workflow-guidance.ps1",
  ".claude/skills/route-request/SKILL.md",
  ".claude/agents/reviewer.md"
)

foreach ($relative in $bridgePaths) {
  Assert-PathExists -Root $target -RelativePath $relative
}

$rootRuntimePaths = @(
  "harness.yaml",
  "agents/registry.yaml",
  "protocols/context-loading.md",
  "flows/feature-development.md",
  "mcp/harness-server/server.js",
  "core/checklists/quality-gates.md",
  "wiki/index.md",
  "memory/index.yaml"
)

foreach ($relative in $rootRuntimePaths) {
  Assert-PathMissing -Root $target -RelativePath $relative
}

$claudeText = Get-Content -LiteralPath (Join-Path $target "CLAUDE.md") -Raw
Assert-True -Condition ($claudeText -like "*Keep this project-specific instruction.*") -Message "Installer overwrote existing CLAUDE.md content."
Assert-True -Condition ($claudeText -like "*BEGIN HARNESS ENGINEERING*") -Message "Installer did not append Harness block to CLAUDE.md."
Assert-True -Condition ($claudeText -like "*.harness/harness.yaml*") -Message "CLAUDE.md bridge does not point to .harness."

$mcp = Get-Content -LiteralPath (Join-Path $target ".mcp.json") -Raw | ConvertFrom-Json
Assert-True -Condition ($null -ne $mcp.mcpServers.harness) -Message "Installer did not register harness MCP server."
Assert-True -Condition (($mcp.mcpServers.harness.args -join "`n") -like "*.harness/mcp/harness-server/server.js*") -Message "Root MCP bridge does not point to .harness server."
Assert-True -Condition ($mcp.mcpServers.harness.env.HARNESS_ROOT -eq ".harness") -Message "Root MCP bridge did not set HARNESS_ROOT=.harness."

$settings = Get-Content -LiteralPath (Join-Path $target ".claude/settings.json") -Raw | ConvertFrom-Json
Assert-True -Condition ($settings.hooks.UserPromptSubmit.Count -ge 1) -Message "Installer did not merge UserPromptSubmit hook."
Assert-True -Condition (($settings.permissions.deny -join "`n") -like "*git push*") -Message "Installer did not merge dangerous operation deny rules."
Assert-True -Condition ((($settings.hooks.UserPromptSubmit.hooks.command) -join "`n") -like "*.claude/hooks/workflow-guidance.ps1*") -Message "Root Claude settings do not call bridge hooks."

$rootSkillText = Get-Content -LiteralPath (Join-Path $target ".claude/skills/route-request/SKILL.md") -Raw
Assert-True -Condition ($rootSkillText -match "(?s)^---\s*.*name:\s*route-request\s*.*description:\s*Use when .+?---") -Message "Root skill bridge has invalid frontmatter."
Assert-True -Condition ($rootSkillText -like "*.harness/.claude/skills/route-request/SKILL.md*") -Message "Root skill bridge does not point to canonical skill."

$rootAgentText = Get-Content -LiteralPath (Join-Path $target ".claude/agents/reviewer.md") -Raw
Assert-True -Condition ($rootAgentText -match "(?s)^---\s*.*name:\s*reviewer\s*.*description:\s*Use when .+?---") -Message "Root subagent bridge has invalid frontmatter."
Assert-True -Condition ($rootAgentText -like "*.harness/.claude/agents/reviewer.md*") -Message "Root subagent bridge does not point to canonical subagent."

Assert-True -Condition (Test-Path -LiteralPath (Join-Path $legacySkill "SKILL.md")) -Message "Installer removed an existing project skill."
Assert-True -Condition (Test-Path -LiteralPath $legacyAgent) -Message "Installer removed an existing project subagent."
Assert-True -Condition (Test-Path -LiteralPath (Join-Path $nestedProjectSkill "SKILL.md")) -Message "Installer removed a nested project skill."

Invoke-CheckedPowerShell -WorkingDirectory (Join-Path $target ".harness") -Arguments @("-File", "scripts/validate-claude-code.ps1")
Invoke-CheckedPowerShell -WorkingDirectory (Join-Path $target ".harness") -Arguments @("-File", "scripts/validate-skills.ps1")

$promptJson = '{"prompt":"Fix login failure and add regression verification"}'
$routeOutput = $promptJson | powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $target ".claude/hooks/workflow-guidance.ps1")
Assert-True -Condition (($routeOutput -join "`n") -like "*Harness Request Router*") -Message "Root workflow guidance hook bridge did not run."
Assert-True -Condition (($routeOutput -join "`n") -like "*.harness/scripts/harness.ps1*") -Message "Root workflow guidance hook did not return a .harness next command."
Assert-True -Condition (Test-Path -LiteralPath (Join-Path $target ".harness/work/request-routing/latest.md")) -Message "Root workflow guidance hook did not write route artifacts under .harness."
Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $target "work/request-routing/latest.md"))) -Message "Root workflow guidance hook wrote route artifacts outside .harness."

$installedHarnessScript = Join-Path $target ".harness/scripts/install-harness.ps1"
New-Item -ItemType Directory -Force -Path (Join-Path $target "scripts") | Out-Null
Set-Content -LiteralPath (Join-Path $target "scripts/install-harness.ps1") -Encoding UTF8 -Value (@(
  "param()",
  "function Install-Harness {",
  "  Write-Output `"old Harness installer`"",
  "}"
) -join [Environment]::NewLine)
Invoke-CheckedPowerShell -WorkingDirectory $target -Arguments @("-File", $installerPath, "-SourceRoot", $repoRoot, "-Target", ".", "-SkipDoctor")
$sourceInstallerText = Get-Content -LiteralPath $installerPath -Raw
$upgradedInstallerText = Get-Content -LiteralPath $installedHarnessScript -Raw
Assert-True -Condition ($upgradedInstallerText -eq $sourceInstallerText) -Message "Installer did not upgrade the canonical Harness installer script."
Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $target "scripts/install-harness.ps1"))) -Message "Installer did not clean a legacy root Harness-managed installer script."

$userScriptTarget = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-user-script-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path (Join-Path $userScriptTarget "scripts") | Out-Null
Set-Content -LiteralPath (Join-Path $userScriptTarget "scripts/install-harness.ps1") -Encoding UTF8 -Value 'Write-Output "project owned installer"'
Invoke-CheckedPowerShell -WorkingDirectory $userScriptTarget -Arguments @("-File", $installerPath, "-SourceRoot", $repoRoot, "-Target", ".", "-SkipDoctor")
$userScriptText = Get-Content -LiteralPath (Join-Path $userScriptTarget "scripts/install-harness.ps1") -Raw
Assert-True -Condition ($userScriptText -like "*project owned installer*") -Message "Installer changed a same-path user script that was not Harness-managed."

$legacyHookTarget = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-legacy-hook-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path (Join-Path $legacyHookTarget ".claude/hooks") | Out-Null
Set-Content -LiteralPath (Join-Path $legacyHookTarget ".claude/hooks/auto-maintenance.ps1") -Encoding UTF8 -Value (@(
  'param(',
  '  [string]$Root = "."',
  ')',
  '',
  '$ErrorActionPreference = "Stop"',
  '$scripts = @(',
  '  "scripts/update-memory-index.ps1",',
  '  "scripts/generate-code-map.ps1",',
  '  "scripts/review-changes.ps1",',
  '  "scripts/update-workflow-gates.ps1"',
  ')',
  'Write-Output "auto-maintenance: OK"'
) -join [Environment]::NewLine)
Invoke-CheckedPowerShell -WorkingDirectory $legacyHookTarget -Arguments @("-File", $installerPath, "-SourceRoot", $repoRoot, "-Target", ".", "-SkipDoctor")
$legacyHookText = Get-Content -LiteralPath (Join-Path $legacyHookTarget ".claude/hooks/auto-maintenance.ps1") -Raw
Assert-True -Condition ($legacyHookText -like "*canonical Harness hook*") -Message "Installer did not upgrade a legacy Harness-managed root hook bridge."
Assert-True -Condition ($legacyHookText -like "*.harness/.claude/hooks/auto-maintenance.ps1*") -Message "Legacy Harness hook was not replaced with .harness bridge."

$mixedSource = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-mixed-source-" + [Guid]::NewGuid().ToString("N"))
$mixedTarget = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-mixed-target-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $mixedSource, (Join-Path $mixedTarget ".claude/skills/documentation-workflow") | Out-Null
Copy-HarnessProbeSource -SourceRoot $repoRoot -Destination $mixedSource
New-Item -ItemType Directory -Force -Path (Join-Path $mixedSource ".claude/skills/documentation-workflow") | Out-Null
Set-Content -LiteralPath (Join-Path $mixedSource ".claude/skills/documentation-workflow/SKILL.md") -Encoding UTF8 -Value "source project skill"
Set-Content -LiteralPath (Join-Path $mixedTarget ".claude/skills/documentation-workflow/SKILL.md") -Encoding UTF8 -Value "target project skill"

Invoke-CheckedPowerShell -WorkingDirectory $mixedTarget -Arguments @("-File", $installerPath, "-SourceRoot", $mixedSource, "-Target", ".", "-SkipDoctor")
$mixedSkillText = Get-Content -LiteralPath (Join-Path $mixedTarget ".claude/skills/documentation-workflow/SKILL.md") -Raw
Assert-True -Condition ($mixedSkillText -like "*target project skill*") -Message "Installer did not preserve the target project skill."
Assert-True -Condition ($mixedSkillText -notlike "*source project skill*") -Message "Installer copied a non-Harness source skill into the target project."
Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $mixedTarget ".harness/.claude/skills/documentation-workflow/SKILL.md"))) -Message "Installer copied a non-Harness source skill into canonical .harness runtime."

$probeSource = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-source-probe-" + [Guid]::NewGuid().ToString("N"))
$probeTarget = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-target-probe-" + [Guid]::NewGuid().ToString("N"))
$probeWorkingDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-working-probe-" + [Guid]::NewGuid().ToString("N"))
$probeFile = "doctor-cwd-" + [Guid]::NewGuid().ToString("N") + ".txt"
New-Item -ItemType Directory -Force -Path $probeSource, $probeTarget, $probeWorkingDirectory | Out-Null
Copy-HarnessProbeSource -SourceRoot $repoRoot -Destination $probeSource
Set-Content -LiteralPath (Join-Path $probeSource "scripts/doctor.ps1") -Encoding UTF8 -Value (@(
  "`$ErrorActionPreference = `"Stop`"",
  "Set-Content -LiteralPath `"$probeFile`" -Encoding UTF8 -Value (Get-Location).Path",
  "Write-Output `"doctor: OK`""
) -join [Environment]::NewLine)

Invoke-CheckedPowerShell -WorkingDirectory $probeWorkingDirectory -Arguments @("-File", $installerPath, "-SourceRoot", $probeSource, "-Target", $probeTarget)
Assert-True -Condition (Test-Path -LiteralPath (Join-Path $probeTarget ".harness/$probeFile")) -Message "Installer doctor did not run from the canonical .harness root."

Write-Output "validate-installer: OK"
