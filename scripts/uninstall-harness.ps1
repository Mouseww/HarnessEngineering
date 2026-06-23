param(
  [string]$Target = "."
)

$ErrorActionPreference = "Stop"

function Resolve-UninstallTarget {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Target does not exist: $Path"
  }

  return (Resolve-Path -LiteralPath $Path).Path
}

function Get-NormalizedFullPath {
  param([string]$Path)

  return ([System.IO.Path]::GetFullPath($Path)).TrimEnd("\", "/")
}

function Assert-PathInsideRoot {
  param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$Path
  )

  $rootPath = Get-NormalizedFullPath -Path $Root
  $targetPath = Get-NormalizedFullPath -Path $Path
  $prefix = $rootPath + [System.IO.Path]::DirectorySeparatorChar

  if (-not $targetPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to remove path outside target root: $Path"
  }
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

  foreach ($skill in Get-HarnessManagedSkills) {
    if ($path -eq ".claude/skills/$skill/SKILL.md") {
      return $true
    }
  }

  foreach ($agent in Get-HarnessManagedAgents) {
    if ($path -eq ".claude/agents/$agent.md") {
      return $true
    }
  }

  return $false
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
    "Uninstall-Harness",
    "harness.yaml",
    "validate-harness",
    "validate-installer",
    "validate-uninstaller",
    "validate-claude-code",
    "harness_status",
    "harness-server",
    "Source: scripts/",
    "BEGIN HARNESS ENGINEERING",
    ".harness/.claude",
    "canonical Harness hook",
    "canonical Harness Engineering",
    "auto-maintenance: OK",
    "scripts/update-memory-index.ps1",
    "scripts/generate-code-map.ps1",
    "scripts/review-changes.ps1",
    "scripts/update-workflow-gates.ps1",
    "Harness Request Router",
    "Harness guard blocked",
    ".claude/agent-memory",
    "tool-audit.jsonl"
  )

  foreach ($marker in $markers) {
    if ($content -like "*$marker*") {
      return $true
    }
  }

  return $false
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

function Remove-HarnessBlock {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    return
  }

  $content = Get-Content -LiteralPath $Path -Raw
  if ($content -notlike "*BEGIN HARNESS ENGINEERING*") {
    return
  }

  $cleaned = [regex]::Replace($content, "(?s)\r?\n?<!-- BEGIN HARNESS ENGINEERING -->.*?<!-- END HARNESS ENGINEERING -->\r?\n?", [Environment]::NewLine)
  $cleaned = $cleaned.TrimEnd()

  if ($cleaned -match "^\s*#\s+(Claude Code Runtime Guide|Agent Runtime Guide|Project README)\s*$") {
    Remove-Item -LiteralPath $Path -Force
    return
  }

  Set-Content -LiteralPath $Path -Encoding UTF8 -Value ($cleaned + [Environment]::NewLine)
}

function Remove-HarnessManagedFile {
  param(
    [string]$TargetRoot,
    [string]$RelativePath
  )

  $path = Join-Path $TargetRoot $RelativePath
  if ((Test-Path -LiteralPath $path) -and (Test-HarnessManagedExistingFile -RelativePath $RelativePath -Path $path)) {
    Remove-Item -LiteralPath $path -Force
  }
}

function Remove-HarnessMcpServer {
  param([string]$TargetRoot)

  $path = Join-Path $TargetRoot ".mcp.json"
  if (-not (Test-Path -LiteralPath $path)) {
    return
  }

  try {
    $json = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
  } catch {
    Write-Warning "Could not parse .mcp.json; leaving it unchanged."
    return
  }

  if ($null -ne $json.mcpServers -and $null -ne $json.mcpServers.harness) {
    $json.mcpServers.PSObject.Properties.Remove("harness")
  }

  if ($null -ne $json.mcpServers -and $json.mcpServers.PSObject.Properties.Count -eq 0) {
    $json.PSObject.Properties.Remove("mcpServers")
  }

  if ($json.PSObject.Properties.Count -eq 0) {
    Remove-Item -LiteralPath $path -Force
  } else {
    $json | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path -Encoding UTF8
  }
}

function Remove-HarnessClaudeSettings {
  param([string]$TargetRoot)

  $path = Join-Path $TargetRoot ".claude/settings.json"
  if (-not (Test-Path -LiteralPath $path)) {
    return
  }

  try {
    $settings = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
  } catch {
    Write-Warning "Could not parse .claude/settings.json; leaving it unchanged."
    return
  }

  $harnessHookFiles = @()
  foreach ($hook in Get-HarnessManagedHooks) {
    $harnessHookFiles += ".claude/hooks/$hook"
    $harnessHookFiles += ".claude\\hooks\\$hook"
  }

  if ($null -ne $settings.hooks) {
    foreach ($eventName in @($settings.hooks.PSObject.Properties.Name)) {
      $keptEntries = New-Object System.Collections.Generic.List[object]
      foreach ($entry in @($settings.hooks.$eventName)) {
        $commands = @(($entry.hooks | ForEach-Object { [string]$_.command }))
        $isHarnessEntry = $false
        foreach ($command in $commands) {
          foreach ($hookFile in $harnessHookFiles) {
            if ($command -like "*$hookFile*") {
              $isHarnessEntry = $true
              break
            }
          }
          if ($isHarnessEntry) {
            break
          }
        }
        if (-not $isHarnessEntry) {
          $keptEntries.Add($entry)
        }
      }

      if ($keptEntries.Count -eq 0) {
        $settings.hooks.PSObject.Properties.Remove($eventName)
      } else {
        $settings.hooks.PSObject.Properties[$eventName].Value = @($keptEntries.ToArray())
      }
    }

    if ($settings.hooks.PSObject.Properties.Count -eq 0) {
      $settings.PSObject.Properties.Remove("hooks")
    }
  }

  $harnessDenyRules = @(
    "Bash(git reset --hard:*)",
    "Bash(git push:*)",
    "Bash(git commit:*)",
    "Bash(git checkout --:*)",
    "Bash(Remove-Item -Recurse:*)",
    "Bash(rm -rf:*)"
  )

  if ($null -ne $settings.permissions) {
    if ($settings.permissions.PSObject.Properties.Name -contains "deny") {
      $deny = @($settings.permissions.deny | Where-Object { $harnessDenyRules -notcontains $_ })
      if ($deny.Count -eq 0) {
        $settings.permissions.PSObject.Properties.Remove("deny")
      } else {
        $settings.permissions.deny = @($deny)
      }
    }

    if (($settings.permissions.PSObject.Properties.Name -contains "defaultMode") -and $settings.permissions.defaultMode -eq "default") {
      $settings.permissions.PSObject.Properties.Remove("defaultMode")
    }

    if ($settings.permissions.PSObject.Properties.Count -eq 0) {
      $settings.PSObject.Properties.Remove("permissions")
    }
  }

  if ($settings.PSObject.Properties.Count -eq 0) {
    Remove-Item -LiteralPath $path -Force
  } else {
    $settings | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path -Encoding UTF8
  }
}

function Remove-HarnessRuntime {
  param([string]$TargetRoot)

  $harnessRoot = Join-Path $TargetRoot ".harness"
  if (-not (Test-Path -LiteralPath $harnessRoot)) {
    return
  }

  $resolvedHarnessRoot = (Resolve-Path -LiteralPath $harnessRoot).Path
  Assert-PathInsideRoot -Root $TargetRoot -Path $resolvedHarnessRoot
  Remove-Item -LiteralPath $resolvedHarnessRoot -Recurse -Force
}

function Uninstall-Harness {
  param([string]$Target = ".")

  $targetRoot = Resolve-UninstallTarget -Path $Target

  Remove-HarnessRuntime -TargetRoot $targetRoot

  foreach ($file in @("CLAUDE.md", "AGENTS.md", "README.md")) {
    Remove-HarnessBlock -Path (Join-Path $targetRoot $file)
  }

  Remove-HarnessMcpServer -TargetRoot $targetRoot
  Remove-HarnessClaudeSettings -TargetRoot $targetRoot

  foreach ($hook in Get-HarnessManagedHooks) {
    Remove-HarnessManagedFile -TargetRoot $targetRoot -RelativePath ".claude/hooks/$hook"
  }

  foreach ($skill in Get-HarnessManagedSkills) {
    Remove-HarnessManagedFile -TargetRoot $targetRoot -RelativePath ".claude/skills/$skill/SKILL.md"
  }

  foreach ($agent in Get-HarnessManagedAgents) {
    Remove-HarnessManagedFile -TargetRoot $targetRoot -RelativePath ".claude/agents/$agent.md"
  }

  $legacyFiles = @(
    "harness.yaml",
    ".claude/rules/delivery.md",
    ".claude/rules/engineering.md",
    ".claude/rules/security.md",
    ".claude/skills/_quality/pressure-scenarios.md"
  )

  foreach ($relative in $legacyFiles) {
    Remove-HarnessManagedFile -TargetRoot $targetRoot -RelativePath $relative
  }

  Remove-EmptyDirectories -Roots @(
    (Join-Path $targetRoot ".claude/hooks"),
    (Join-Path $targetRoot ".claude/agents"),
    (Join-Path $targetRoot ".claude/skills"),
    (Join-Path $targetRoot ".claude/rules"),
    (Join-Path $targetRoot ".claude")
  )

  Write-Output "Harness uninstalled: $targetRoot"
}

if ($PSCommandPath) {
  Uninstall-Harness -Target $Target
}
