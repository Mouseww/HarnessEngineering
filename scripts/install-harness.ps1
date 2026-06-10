param(
  [string]$Target = ".",
  [string]$SourceRoot,
  [string]$Repo = "Mouseww/HarnessEngineering",
  [string]$Ref = "main",
  [switch]$Force,
  [switch]$SkipDoctor
)

$ErrorActionPreference = "Stop"

function Ensure-Directory {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Resolve-InstallTarget {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }

  return (Resolve-Path -LiteralPath $Path).Path
}

function Get-DownloadedSource {
  param(
    [string]$Repository,
    [string]$Revision
  )

  $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-source-" + [Guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

  $zipPath = Join-Path $tempRoot "source.zip"
  $zipUrl = "https://codeload.github.com/$Repository/zip/refs/heads/$Revision"
  Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
  Expand-Archive -LiteralPath $zipPath -DestinationPath $tempRoot -Force

  $source = Get-ChildItem -LiteralPath $tempRoot -Directory | Where-Object { $_.Name -ne "__MACOSX" } | Select-Object -First 1
  if ($null -eq $source) {
    throw "Downloaded Harness archive did not contain a source directory."
  }

  return $source.FullName
}

function Resolve-HarnessSource {
  param(
    [string]$LocalSourceRoot,
    [string]$Repository,
    [string]$Revision
  )

  if (-not [string]::IsNullOrWhiteSpace($LocalSourceRoot)) {
    return (Resolve-Path -LiteralPath $LocalSourceRoot).Path
  }

  if ($PSCommandPath) {
    $candidate = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
    if (Test-Path -LiteralPath (Join-Path $candidate "harness.yaml")) {
      return $candidate
    }
  }

  return Get-DownloadedSource -Repository $Repository -Revision $Revision
}

function Get-RelativePath {
  param(
    [string]$Root,
    [string]$Path
  )

  return $Path.Substring($Root.Length).TrimStart("\", "/") -replace "\\", "/"
}

function Test-HarnessManagedRelativePath {
  param([string]$RelativePath)

  $path = $RelativePath -replace "\\", "/"
  if ($path -notlike ".claude/*") {
    return $true
  }

  $managedClaudeFiles = @(
    ".claude/settings.json",
    ".claude/hooks/auto-maintenance.ps1",
    ".claude/hooks/post-edit-audit.ps1",
    ".claude/hooks/pre-tool-guard.ps1",
    ".claude/hooks/session-context.ps1",
    ".claude/hooks/workflow-guidance.ps1",
    ".claude/rules/delivery.md",
    ".claude/rules/engineering.md",
    ".claude/rules/security.md",
    ".claude/skills/_quality/pressure-scenarios.md"
  )

  if ($managedClaudeFiles -contains $path) {
    return $true
  }

  $managedSkills = @(
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

  foreach ($skill in $managedSkills) {
    if ($path -eq ".claude/skills/$skill/SKILL.md") {
      return $true
    }
  }

  $managedAgents = @(
    "architect",
    "implementer",
    "mcp-curator",
    "memory-curator",
    "release-manager",
    "reviewer",
    "tester"
  )

  foreach ($agent in $managedAgents) {
    if ($path -eq ".claude/agents/$agent.md") {
      return $true
    }
  }

  return $false
}

function Get-HarnessManagedHooks {
  return @(
    "auto-maintenance.ps1",
    "post-edit-audit.ps1",
    "pre-tool-guard.ps1",
    "session-context.ps1",
    "workflow-guidance.ps1"
  )
}

function Get-HarnessManagedSkills {
  return @(
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
}

function Get-HarnessManagedAgents {
  return @(
    "architect",
    "implementer",
    "mcp-curator",
    "memory-curator",
    "release-manager",
    "reviewer",
    "tester"
  )
}

function Test-HarnessManagedExistingFile {
  param(
    [string]$RelativePath,
    [string]$Path
  )

  if (-not (Test-HarnessManagedRelativePath -RelativePath $RelativePath)) {
    return $false
  }
  if (-not (Test-Path -LiteralPath $Path)) {
    return $false
  }

  $content = Get-Content -LiteralPath $Path -Raw
  $markers = @(
    "Harness Engineering",
    "HarnessEngineering",
    "Install-Harness",
    "harness.yaml",
    "validate-harness",
    "validate-installer",
    "validate-claude-code",
    "harness_status",
    "harness-server",
    "Source: scripts/",
    "BEGIN HARNESS ENGINEERING",
    ".harness/.claude",
    "canonical Harness hook",
    "canonical Harness Engineering"
  )

  foreach ($marker in $markers) {
    if ($content -like "*$marker*") {
      return $true
    }
  }

  return $false
}

function Test-HarnessFileConflict {
  param(
    [string]$RelativePath,
    [string]$SourcePath,
    [string]$TargetPath,
    [bool]$Overwrite
  )

  if (-not (Test-Path -LiteralPath $TargetPath)) {
    return $false
  }
  if ($Overwrite) {
    return $false
  }

  $sourceText = Get-Content -LiteralPath $SourcePath -Raw
  $targetText = Get-Content -LiteralPath $TargetPath -Raw
  if ($sourceText -eq $targetText) {
    return $false
  }

  return -not (Test-HarnessManagedExistingFile -RelativePath $RelativePath -Path $TargetPath)
}

function Copy-HarnessTree {
  param(
    [string]$Source,
    [string]$Destination,
    [string[]]$Directories,
    [string[]]$Files,
    [string[]]$ExcludedRelativePaths,
    [bool]$Overwrite
  )

  foreach ($file in $Files) {
    $sourcePath = Join-Path $Source $file
    if (-not (Test-Path -LiteralPath $sourcePath)) {
      throw "Harness source is missing required file: $file"
    }
    $targetPath = Join-Path $Destination $file
    if (Test-HarnessFileConflict -RelativePath $file -SourcePath $sourcePath -TargetPath $targetPath -Overwrite $Overwrite) {
      throw "Target file already exists and differs: $file. Re-run with -Force to overwrite."
    }
  }

  foreach ($directory in $Directories) {
    $sourceDirectory = Join-Path $Source $directory
    if (-not (Test-Path -LiteralPath $sourceDirectory)) {
      throw "Harness source is missing required directory: $directory"
    }
    $sourceFiles = @(Get-ChildItem -LiteralPath $sourceDirectory -File -Recurse)
    foreach ($sourceFile in $sourceFiles) {
      $relative = Get-RelativePath -Root $Source -Path $sourceFile.FullName
      if ($ExcludedRelativePaths -contains $relative) {
        continue
      }
      if (-not (Test-HarnessManagedRelativePath -RelativePath $relative)) {
        continue
      }
      $targetPath = Join-Path $Destination $relative
      if (Test-HarnessFileConflict -RelativePath $relative -SourcePath $sourceFile.FullName -TargetPath $targetPath -Overwrite $Overwrite) {
        throw "Target file already exists and differs: $relative. Re-run with -Force to overwrite."
      }
    }
  }

  foreach ($file in $Files) {
    $sourcePath = Join-Path $Source $file
    $targetPath = Join-Path $Destination $file
    Ensure-Directory -Path (Split-Path -Parent $targetPath)
    Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
  }

  foreach ($directory in $Directories) {
    $sourceDirectory = Join-Path $Source $directory
    $sourceFiles = @(Get-ChildItem -LiteralPath $sourceDirectory -File -Recurse)
    foreach ($sourceFile in $sourceFiles) {
      $relative = Get-RelativePath -Root $Source -Path $sourceFile.FullName
      if ($ExcludedRelativePaths -contains $relative) {
        continue
      }
      if (-not (Test-HarnessManagedRelativePath -RelativePath $relative)) {
        continue
      }
      $targetPath = Join-Path $Destination $relative
      Ensure-Directory -Path (Split-Path -Parent $targetPath)
      Copy-Item -LiteralPath $sourceFile.FullName -Destination $targetPath -Force
    }
  }
}

function Add-HarnessBlock {
  param(
    [string]$Path,
    [string]$Title,
    [string]$Body
  )

  $block = @(
    "",
    "<!-- BEGIN HARNESS ENGINEERING -->",
    "## Harness Engineering",
    "",
    $Body,
    "",
    "<!-- END HARNESS ENGINEERING -->"
  ) -join [Environment]::NewLine

  if (-not (Test-Path -LiteralPath $Path)) {
    $content = @(
      "# $Title",
      $block
    ) -join [Environment]::NewLine
    Set-Content -LiteralPath $Path -Encoding UTF8 -Value $content
    return
  }

  $existing = Get-Content -LiteralPath $Path -Raw
  if ($existing -notlike "*BEGIN HARNESS ENGINEERING*") {
    Add-Content -LiteralPath $Path -Encoding UTF8 -Value $block
  }
}

function Merge-McpJson {
  param(
    [string]$SourcePath,
    [string]$TargetPath,
    [string]$HarnessRootRelative = "."
  )

  $source = Get-Content -LiteralPath $SourcePath -Raw | ConvertFrom-Json
  $serverPath = "mcp/harness-server/server.js"
  if ($HarnessRootRelative -ne ".") {
    $serverPath = "$HarnessRootRelative/mcp/harness-server/server.js"
  }
  $serverPath = $serverPath -replace "\\", "/"
  $source.mcpServers.harness.args = @($serverPath)
  if ($null -eq $source.mcpServers.harness.env) {
    $source.mcpServers.harness | Add-Member -NotePropertyName "env" -NotePropertyValue ([pscustomobject]@{})
  }
  if ($source.mcpServers.harness.env.PSObject.Properties.Name -contains "HARNESS_ROOT") {
    $source.mcpServers.harness.env.HARNESS_ROOT = $HarnessRootRelative
  } else {
    $source.mcpServers.harness.env | Add-Member -NotePropertyName "HARNESS_ROOT" -NotePropertyValue $HarnessRootRelative
  }

  if (Test-Path -LiteralPath $TargetPath) {
    $target = Get-Content -LiteralPath $TargetPath -Raw | ConvertFrom-Json
  } else {
    $target = [pscustomobject]@{}
  }

  if ($null -eq $target.mcpServers) {
    $target | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue ([pscustomobject]@{})
  }

  if ($null -ne $target.mcpServers.harness) {
    $target.mcpServers.PSObject.Properties.Remove("harness")
  }
  $target.mcpServers | Add-Member -NotePropertyName "harness" -NotePropertyValue $source.mcpServers.harness

  Ensure-Directory -Path (Split-Path -Parent $TargetPath)
  $target | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $TargetPath -Encoding UTF8
}

function Set-HarnessTextFile {
  param(
    [string]$RelativePath,
    [string]$TargetPath,
    [string]$Content,
    [bool]$Overwrite
  )

  if (Test-Path -LiteralPath $TargetPath) {
    $existing = Get-Content -LiteralPath $TargetPath -Raw
    if ($existing -ne $Content -and -not $Overwrite -and -not (Test-HarnessManagedExistingFile -RelativePath $RelativePath -Path $TargetPath)) {
      throw "Target file already exists and differs: $RelativePath. Re-run with -Force to overwrite."
    }
  }

  Ensure-Directory -Path (Split-Path -Parent $TargetPath)
  Set-Content -LiteralPath $TargetPath -Encoding UTF8 -Value $Content
}

function Get-FrontmatterValue {
  param(
    [string]$Path,
    [string]$Name
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return $null
  }

  $content = Get-Content -LiteralPath $Path -Raw
  $escapedName = [regex]::Escape($Name)
  $match = [regex]::Match($content, "(?m)^$escapedName\s*:\s*(.+?)\s*$")
  if ($match.Success) {
    return $match.Groups[1].Value.Trim()
  }

  return $null
}

function New-HookBridgeContent {
  param([string]$HookFile)

  return (@(
    'param()',
    '',
    '$ErrorActionPreference = "Stop"',
    '$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "../..")).Path',
    '$harnessRoot = Join-Path $projectRoot ".harness"',
    ('$scriptPath = Join-Path $harnessRoot ".claude/hooks/' + $HookFile + '"'),
    'if (-not (Test-Path -LiteralPath $scriptPath)) {',
    ('  throw "Missing canonical Harness hook: .harness/.claude/hooks/' + $HookFile + '"'),
    '}',
    '',
    '$stdin = [Console]::In.ReadToEnd()',
    'Push-Location -LiteralPath $projectRoot',
    'try {',
    '  if ([string]::IsNullOrEmpty($stdin)) {',
    '    powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath -Root $harnessRoot',
    '  } else {',
    '    $stdin | powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath -Root $harnessRoot',
    '  }',
    '  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }',
    '} finally {',
    '  Pop-Location',
    '}'
  ) -join [Environment]::NewLine)
}

function New-SkillBridgeContent {
  param(
    [string]$Name,
    [string]$SourcePath
  )

  $description = Get-FrontmatterValue -Path $SourcePath -Name "description"
  if ([string]::IsNullOrWhiteSpace($description)) {
    $description = "Use when the Harness Engineering $Name skill is selected for the current request."
  }

  return (@(
    "---",
    "name: $Name",
    "description: $description",
    "---",
    "",
    "# $Name Bridge",
    "",
    "Use the canonical Harness Engineering skill at `.harness/.claude/skills/$Name/SKILL.md`.",
    "Load that file and follow it as the source of truth before acting."
  ) -join [Environment]::NewLine)
}

function New-AgentBridgeContent {
  param(
    [string]$Name,
    [string]$SourcePath
  )

  $description = Get-FrontmatterValue -Path $SourcePath -Name "description"
  if ([string]::IsNullOrWhiteSpace($description)) {
    $description = "Use when the Harness Engineering $Name subagent role is selected for the current request."
  }

  return (@(
    "---",
    "name: $Name",
    "description: $description",
    "---",
    "",
    "# $Name Bridge",
    "",
    "Use the canonical Harness Engineering subagent at `.harness/.claude/agents/$Name.md`.",
    "Load that file and follow it as the source of truth before acting."
  ) -join [Environment]::NewLine)
}

function Install-RootClaudeBridges {
  param(
    [string]$Source,
    [string]$TargetRoot,
    [bool]$Overwrite
  )

  foreach ($hook in Get-HarnessManagedHooks) {
    $relative = ".claude/hooks/$hook"
    $targetPath = Join-Path $TargetRoot $relative
    Set-HarnessTextFile -RelativePath $relative -TargetPath $targetPath -Content (New-HookBridgeContent -HookFile $hook) -Overwrite $Overwrite
  }

  foreach ($skill in Get-HarnessManagedSkills) {
    $relative = ".claude/skills/$skill/SKILL.md"
    $sourcePath = Join-Path $Source $relative
    $targetPath = Join-Path $TargetRoot $relative
    Set-HarnessTextFile -RelativePath $relative -TargetPath $targetPath -Content (New-SkillBridgeContent -Name $skill -SourcePath $sourcePath) -Overwrite $Overwrite
  }

  foreach ($agent in Get-HarnessManagedAgents) {
    $relative = ".claude/agents/$agent.md"
    $sourcePath = Join-Path $Source $relative
    $targetPath = Join-Path $TargetRoot $relative
    Set-HarnessTextFile -RelativePath $relative -TargetPath $targetPath -Content (New-AgentBridgeContent -Name $agent -SourcePath $sourcePath) -Overwrite $Overwrite
  }
}

function Remove-EmptyDirectories {
  param([string[]]$Roots)

  foreach ($root in $Roots) {
    if ([string]::IsNullOrWhiteSpace($root) -or -not (Test-Path -LiteralPath $root)) {
      continue
    }

    $directories = @(Get-ChildItem -LiteralPath $root -Directory -Recurse | Sort-Object FullName -Descending)
    $directories += Get-Item -LiteralPath $root
    foreach ($directory in $directories) {
      $children = @(Get-ChildItem -LiteralPath $directory.FullName -Force)
      if ($children.Count -eq 0) {
        Remove-Item -LiteralPath $directory.FullName -Force
      }
    }
  }
}

function Remove-LegacyRootHarnessRuntime {
  param(
    [string]$Source,
    [string]$TargetRoot
  )

  $legacyDirectories = @(
    "agents",
    "core",
    "flows",
    "mcp",
    "protocols",
    "scripts",
    "wiki"
  )
  $removedDirectoryRoots = New-Object System.Collections.Generic.List[string]

  foreach ($directory in $legacyDirectories) {
    $sourceDirectory = Join-Path $Source $directory
    $targetDirectory = Join-Path $TargetRoot $directory
    if (-not (Test-Path -LiteralPath $sourceDirectory)) {
      continue
    }

    foreach ($sourceFile in @(Get-ChildItem -LiteralPath $sourceDirectory -File -Recurse)) {
      $relative = Get-RelativePath -Root $Source -Path $sourceFile.FullName
      $targetPath = Join-Path $TargetRoot $relative
      if ((Test-Path -LiteralPath $targetPath) -and (Test-HarnessManagedExistingFile -RelativePath $relative -Path $targetPath)) {
        Remove-Item -LiteralPath $targetPath -Force
      }
    }

    if (Test-Path -LiteralPath $targetDirectory) {
      $removedDirectoryRoots.Add($targetDirectory)
    }
  }

  foreach ($file in @("harness.yaml")) {
    $targetPath = Join-Path $TargetRoot $file
    if ((Test-Path -LiteralPath $targetPath) -and (Test-HarnessManagedExistingFile -RelativePath $file -Path $targetPath)) {
      Remove-Item -LiteralPath $targetPath -Force
    }
  }

  $legacyClaudeFiles = @(
    ".claude/rules/delivery.md",
    ".claude/rules/engineering.md",
    ".claude/rules/security.md",
    ".claude/skills/_quality/pressure-scenarios.md"
  )

  foreach ($relative in $legacyClaudeFiles) {
    $targetPath = Join-Path $TargetRoot $relative
    if ((Test-Path -LiteralPath $targetPath) -and (Test-HarnessManagedExistingFile -RelativePath $relative -Path $targetPath)) {
      Remove-Item -LiteralPath $targetPath -Force
    }
  }

  Remove-EmptyDirectories -Roots @($removedDirectoryRoots.ToArray(), (Join-Path $TargetRoot ".claude/rules"), (Join-Path $TargetRoot ".claude/skills/_quality"))
}

function Merge-ClaudeSettings {
  param(
    [string]$SourcePath,
    [string]$TargetPath
  )

  $source = Get-Content -LiteralPath $SourcePath -Raw | ConvertFrom-Json
  if (Test-Path -LiteralPath $TargetPath) {
    $target = Get-Content -LiteralPath $TargetPath -Raw | ConvertFrom-Json
  } else {
    $target = [pscustomobject]@{}
  }

  if ($null -eq $target.permissions) {
    $target | Add-Member -NotePropertyName "permissions" -NotePropertyValue ([pscustomobject]@{})
  }
  if ($null -eq $target.permissions.defaultMode -and $null -ne $source.permissions.defaultMode) {
    $target.permissions | Add-Member -NotePropertyName "defaultMode" -NotePropertyValue $source.permissions.defaultMode
  }

  $deny = New-Object System.Collections.Generic.List[string]
  foreach ($item in @($target.permissions.deny)) {
    if (-not [string]::IsNullOrWhiteSpace($item) -and -not $deny.Contains($item)) {
      $deny.Add($item)
    }
  }
  foreach ($item in @($source.permissions.deny)) {
    if (-not [string]::IsNullOrWhiteSpace($item) -and -not $deny.Contains($item)) {
      $deny.Add($item)
    }
  }
  if ($target.permissions.PSObject.Properties.Name -contains "deny") {
    $target.permissions.deny = @($deny)
  } else {
    $target.permissions | Add-Member -NotePropertyName "deny" -NotePropertyValue @($deny)
  }

  if ($null -eq $target.hooks) {
    $target | Add-Member -NotePropertyName "hooks" -NotePropertyValue ([pscustomobject]@{})
  }

  foreach ($eventName in $source.hooks.PSObject.Properties.Name) {
    if ($target.hooks.PSObject.Properties.Name -notcontains $eventName) {
      $target.hooks | Add-Member -NotePropertyName $eventName -NotePropertyValue @()
    }

    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($entry in @($target.hooks.$eventName)) {
      $entries.Add($entry)
    }

    foreach ($sourceEntry in @($source.hooks.$eventName)) {
      $sourceCommand = (($sourceEntry.hooks | ForEach-Object { $_.command }) -join "`n")
      $exists = $false
      foreach ($existingEntry in $entries) {
        $existingCommand = (($existingEntry.hooks | ForEach-Object { $_.command }) -join "`n")
        if ($existingCommand -eq $sourceCommand) {
          $exists = $true
          break
        }
      }
      if (-not $exists) {
        $entries.Add($sourceEntry)
      }
    }

    $target.hooks.PSObject.Properties[$eventName].Value = @($entries.ToArray())
  }

  Ensure-Directory -Path (Split-Path -Parent $TargetPath)
  $target | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $TargetPath -Encoding UTF8
}

function Initialize-HarnessState {
  param([string]$Destination)

  $directories = @(
    "memory/team",
    "memory/project",
    "memory/agents/claude-code",
    "memory/agents/codex",
    "work/active",
    "work/done",
    "work/archived",
    "work/brainstorms",
    "work/designs",
    "work/plans",
    "work/request-routing"
  )

  foreach ($directory in $directories) {
    Ensure-Directory -Path (Join-Path $Destination $directory)
    $gitkeep = Join-Path $Destination "$directory/.gitkeep"
    if (-not (Test-Path -LiteralPath $gitkeep)) {
      Set-Content -LiteralPath $gitkeep -Encoding UTF8 -Value ""
    }
  }

  $memoryIndex = Join-Path $Destination "memory/index.yaml"
  if (-not (Test-Path -LiteralPath $memoryIndex)) {
    Set-Content -LiteralPath $memoryIndex -Encoding UTF8 -Value @(
      "version: 1",
      "policy: protocols/memory-contract.md",
      "layers:",
      "  team: memory/team",
      "  project: memory/project",
      "  agents: memory/agents",
      "indexes:",
      "  team: memory/team/index.md",
      "  project: memory/project/index.md",
      "  claude-code: memory/agents/claude-code/index.md",
      "  codex: memory/agents/codex/index.md"
    )
  }

  $memoryFiles = @{
    "memory/team/index.md" = "# Team Memory`n`nLong-lived reusable team standards and cross-project knowledge live in this directory."
    "memory/project/index.md" = "# Project Memory`n`nProject facts, decisions, and verification records live in this directory."
    "memory/agents/claude-code/index.md" = "# Claude Code Memory`n`nClaude Code runtime adaptation experience lives in this directory."
    "memory/agents/codex/index.md" = "# Codex Memory`n`nCodex runtime adaptation experience lives in this directory."
  }

  foreach ($relative in $memoryFiles.Keys) {
    $path = Join-Path $Destination $relative
    if (-not (Test-Path -LiteralPath $path)) {
      Set-Content -LiteralPath $path -Encoding UTF8 -Value $memoryFiles[$relative]
    }
  }
}

function Install-Harness {
  param(
    [string]$Target = ".",
    [string]$SourceRoot,
    [string]$Repo = "Mouseww/HarnessEngineering",
    [string]$Ref = "main",
    [switch]$Force,
    [switch]$SkipDoctor
  )

  $targetRoot = Resolve-InstallTarget -Path $Target
  $source = Resolve-HarnessSource -LocalSourceRoot $SourceRoot -Repository $Repo -Revision $Ref
  $harnessRootRelative = ".harness"
  $harnessRoot = Join-Path $targetRoot $harnessRootRelative

  $directories = @(
    ".claude",
    "agents",
    "core",
    "flows",
    "mcp",
    "protocols",
    "scripts",
    "wiki"
  )
  $files = @(
    "README.md",
    "CLAUDE.md",
    "AGENTS.md",
    "harness.yaml",
    ".mcp.json"
  )
  $excluded = @()

  Copy-HarnessTree -Source $source -Destination $harnessRoot -Directories $directories -Files $files -ExcludedRelativePaths $excluded -Overwrite $Force.IsPresent
  Initialize-HarnessState -Destination $harnessRoot
  Remove-LegacyRootHarnessRuntime -Source $source -TargetRoot $targetRoot

  $claudeBody = "This project uses Harness Engineering. Read `.harness/harness.yaml`, `.harness/agents/registry.yaml`, and `.harness/protocols/context-loading.md`; then use root Claude bridge skills from `.claude/skills/` to load canonical skills under `.harness/.claude/skills/`."
  $agentsBody = "This project uses Harness Engineering for Codex and other agents. Read `.harness/harness.yaml`, `.harness/agents/registry.yaml`, and the current agent manifest under `.harness/agents/` before modifying files."
  $readmeBody = "This project has Harness Engineering installed under `.harness/`. Run `powershell -NoProfile -ExecutionPolicy Bypass -File `".harness/scripts/doctor.ps1`"` from the repository root to verify the runtime."

  Add-HarnessBlock -Path (Join-Path $targetRoot "CLAUDE.md") -Title "Claude Code Runtime Guide" -Body $claudeBody
  Add-HarnessBlock -Path (Join-Path $targetRoot "AGENTS.md") -Title "Agent Runtime Guide" -Body $agentsBody
  Add-HarnessBlock -Path (Join-Path $targetRoot "README.md") -Title "Project README" -Body $readmeBody

  Merge-McpJson -SourcePath (Join-Path $source ".mcp.json") -TargetPath (Join-Path $targetRoot ".mcp.json") -HarnessRootRelative $harnessRootRelative
  Merge-ClaudeSettings -SourcePath (Join-Path $source ".claude/settings.json") -TargetPath (Join-Path $targetRoot ".claude/settings.json")
  Install-RootClaudeBridges -Source $source -TargetRoot $targetRoot -Overwrite $Force.IsPresent

  if (-not $SkipDoctor) {
    Push-Location -LiteralPath $harnessRoot
    try {
      powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/doctor.ps1"
      if ($LASTEXITCODE -ne 0) {
        throw "Installed Harness doctor validation failed."
      }
    } finally {
      Pop-Location
    }
  }

  Write-Output "Harness installed: $targetRoot"
  Write-Output "Runtime: $harnessRoot"
  Write-Output "Next: start Claude Code from the target root."
}

if ($PSCommandPath) {
  Install-Harness -Target $Target -SourceRoot $SourceRoot -Repo $Repo -Ref $Ref -Force:$Force.IsPresent -SkipDoctor:$SkipDoctor.IsPresent
}
