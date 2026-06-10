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
    if ((Test-Path -LiteralPath $targetPath) -and -not $Overwrite) {
      $sourceText = Get-Content -LiteralPath $sourcePath -Raw
      $targetText = Get-Content -LiteralPath $targetPath -Raw
      if ($sourceText -ne $targetText) {
        throw "Target file already exists and differs: $file. Re-run with -Force to overwrite."
      }
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
      if ((Test-Path -LiteralPath $targetPath) -and -not $Overwrite) {
        $sourceText = Get-Content -LiteralPath $sourceFile.FullName -Raw
        $targetText = Get-Content -LiteralPath $targetPath -Raw
        if ($sourceText -ne $targetText) {
          throw "Target file already exists and differs: $relative. Re-run with -Force to overwrite."
        }
      }
    }
  }

  foreach ($file in $Files) {
    $sourcePath = Join-Path $Source $file
    $targetPath = Join-Path $Destination $file
    Ensure-Directory -Path (Split-Path -Parent $targetPath)
    Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force:$Overwrite
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
      Copy-Item -LiteralPath $sourceFile.FullName -Destination $targetPath -Force:$Overwrite
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
    [string]$TargetPath
  )

  $source = Get-Content -LiteralPath $SourcePath -Raw | ConvertFrom-Json
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
    "harness.yaml"
  )
  $excluded = @(
    ".claude/settings.json"
  )

  Copy-HarnessTree -Source $source -Destination $targetRoot -Directories $directories -Files $files -ExcludedRelativePaths $excluded -Overwrite $Force.IsPresent

  $claudeBody = "This project uses Harness Engineering. Read `harness.yaml`, `agents/registry.yaml`, and `protocols/context-loading.md`; then route requests before implementation and run verification before delivery."
  $agentsBody = "This project uses Harness Engineering for Codex and other agents. Read `harness.yaml`, `agents/registry.yaml`, and the current agent manifest before modifying files."
  $readmeBody = "This project has Harness Engineering installed. Run `powershell -NoProfile -ExecutionPolicy Bypass -File `"scripts/doctor.ps1`"` from the repository root to verify the runtime."

  Add-HarnessBlock -Path (Join-Path $targetRoot "CLAUDE.md") -Title "Claude Code Runtime Guide" -Body $claudeBody
  Add-HarnessBlock -Path (Join-Path $targetRoot "AGENTS.md") -Title "Agent Runtime Guide" -Body $agentsBody
  Add-HarnessBlock -Path (Join-Path $targetRoot "README.md") -Title "Project README" -Body $readmeBody

  Merge-McpJson -SourcePath (Join-Path $source ".mcp.json") -TargetPath (Join-Path $targetRoot ".mcp.json")
  Merge-ClaudeSettings -SourcePath (Join-Path $source ".claude/settings.json") -TargetPath (Join-Path $targetRoot ".claude/settings.json")
  Initialize-HarnessState -Destination $targetRoot

  if (-not $SkipDoctor) {
    Push-Location -LiteralPath $targetRoot
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
  Write-Output "Next: start Claude Code from the target root."
}

if ($PSCommandPath) {
  Install-Harness -Target $Target -SourceRoot $SourceRoot -Repo $Repo -Ref $Ref -Force:$Force.IsPresent -SkipDoctor:$SkipDoctor.IsPresent
}
