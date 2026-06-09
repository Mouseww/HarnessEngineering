param(
  [Parameter(Position = 0, Mandatory = $true)]
  [ValidateSet("status", "new-task", "capture-memory", "brainstorm", "design", "plan", "checkpoint", "workflow-status")]
  [string]$Command,

  [string]$Root = ".",
  [switch]$Json,

  [string]$Id,
  [string]$Title,
  [string]$Flow,
  [string]$Goal,
  [string]$Verify,
  [switch]$Force,

  [string]$Topic,
  [string]$Decision,
  [string]$Constraints,
  [string]$Design,
  [string]$Step,
  [string]$Evidence,

  [string]$Layer = "project",
  [string]$Fact,
  [string]$Source,
  [switch]$Verified
)

$ErrorActionPreference = "Stop"

function Resolve-Root {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }

  return (Resolve-Path -LiteralPath $Path).Path
}

function Ensure-Directory {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Assert-SafeId {
  param(
    [Parameter(Mandatory = $true)][string]$Value,
    [Parameter(Mandatory = $true)][string]$Name
  )

  if ($Value -notmatch "^[A-Za-z0-9][A-Za-z0-9._-]*$") {
    throw "$Name must start with a letter or number and contain only letters, numbers, dot, underscore, or hyphen."
  }
}

function Convert-ToSlug {
  param([string]$Value)

  $slug = $Value.ToLowerInvariant() -replace "[^a-z0-9]+", "-"
  $slug = $slug.Trim("-")
  if ([string]::IsNullOrWhiteSpace($slug)) {
    $slug = "memory"
  }
  return $slug
}

function Get-HarnessStatus {
  param([string]$HarnessRoot)

  $activeDir = Join-Path $HarnessRoot "work/active"
  $memoryDir = Join-Path $HarnessRoot "memory"

  $activeTasks = @()
  if (Test-Path -LiteralPath $activeDir) {
    $activeTasks = @(Get-ChildItem -LiteralPath $activeDir -Filter "*.md" -File)
  }

  $memoryEntries = @()
  if (Test-Path -LiteralPath $memoryDir) {
    $memoryEntries = @(Get-ChildItem -LiteralPath $memoryDir -Filter "*.md" -File -Recurse | Where-Object { $_.Name -ne "index.md" })
  }

  return [ordered]@{
    root = $HarnessRoot
    activeTasksCount = $activeTasks.Count
    activeTasks = @($activeTasks | ForEach-Object { $_.BaseName })
    memoryEntriesCount = $memoryEntries.Count
    memoryEntries = @($memoryEntries | ForEach-Object { $_.FullName.Substring($HarnessRoot.Length).TrimStart("\", "/") -replace "\\", "/" })
  }
}

function New-HarnessTask {
  param(
    [string]$HarnessRoot,
    [string]$TaskId,
    [string]$TaskTitle,
    [string]$TaskFlow,
    [string]$TaskGoal,
    [string]$VerifyCommand,
    [bool]$Overwrite
  )

  if ([string]::IsNullOrWhiteSpace($TaskId)) { throw "new-task requires -Id." }
  if ([string]::IsNullOrWhiteSpace($TaskTitle)) { throw "new-task requires -Title." }
  if ([string]::IsNullOrWhiteSpace($TaskFlow)) { throw "new-task requires -Flow." }
  if ([string]::IsNullOrWhiteSpace($TaskGoal)) { throw "new-task requires -Goal." }

  Assert-SafeId -Value $TaskId -Name "Id"
  Assert-SafeId -Value $TaskFlow -Name "Flow"

  $flowPath = Join-Path $HarnessRoot "flows/$TaskFlow.md"
  if (-not (Test-Path -LiteralPath $flowPath)) {
    throw "Flow does not exist: flows/$TaskFlow.md"
  }

  $activeDir = Join-Path $HarnessRoot "work/active"
  Ensure-Directory -Path $activeDir

  $taskPath = Join-Path $activeDir "$TaskId.md"
  if ((Test-Path -LiteralPath $taskPath) -and -not $Overwrite) {
    throw "Task already exists: work/active/$TaskId.md"
  }

  $createdAt = (Get-Date).ToUniversalTime().ToString("o")
  $verifyText = if ([string]::IsNullOrWhiteSpace($VerifyCommand)) { "Not specified. Add a verification command before delivery." } else { $VerifyCommand }

  $content = @(
    "# $TaskTitle",
    "",
    "Status: active",
    "",
    "## Metadata",
    "",
    "- ID: $TaskId",
    "- Flow: $TaskFlow",
    "- Created: $createdAt",
    "",
    "## Goal",
    "",
    $TaskGoal,
    "",
    "## Non-goals",
    "",
    "- Do not expand into unconfirmed scope.",
    "- Do not perform unauthorized git or production operations.",
    "",
    "## Execution Steps",
    "",
    "- [ ] Load context.",
    "- [ ] Confirm file scope.",
    "- [ ] Implement the minimal change.",
    "- [ ] Run verification command.",
    "- [ ] Review changes.",
    "- [ ] Deliver and capture required memory.",
    "",
    "## Verification Command",
    "",
    '```powershell',
    $verifyText,
    '```',
    "",
    "## Risks",
    "",
    "- Do not deliver if verification is missing or failing.",
    "- Request user confirmation before any high-risk operation."
  ) -join [Environment]::NewLine

  Set-Content -LiteralPath $taskPath -Encoding UTF8 -Value $content
  Write-Output "Created task: $taskPath"
}

function Add-HarnessMemory {
  param(
    [string]$HarnessRoot,
    [string]$MemoryLayer,
    [string]$MemoryTitle,
    [string]$MemoryFact,
    [string]$MemorySource,
    [bool]$IsVerified
  )

  if ([string]::IsNullOrWhiteSpace($MemoryTitle)) { throw "capture-memory requires -Title." }
  if ([string]::IsNullOrWhiteSpace($MemoryFact)) { throw "capture-memory requires -Fact." }
  if ([string]::IsNullOrWhiteSpace($MemorySource)) { throw "capture-memory requires -Source." }

  $layerPath = switch ($MemoryLayer) {
    "team" { "memory/team" }
    "project" { "memory/project" }
    "claude-code" { "memory/agents/claude-code" }
    "codex" { "memory/agents/codex" }
    default { throw "Unsupported memory layer: $MemoryLayer" }
  }

  $directory = Join-Path $HarnessRoot $layerPath
  Ensure-Directory -Path $directory

  $date = (Get-Date).ToString("yyyy-MM-dd")
  $slug = Convert-ToSlug -Value $MemoryTitle
  $fileName = "$date-$slug.md"
  $path = Join-Path $directory $fileName
  $counter = 2
  while (Test-Path -LiteralPath $path) {
    $fileName = "$date-$slug-$counter.md"
    $path = Join-Path $directory $fileName
    $counter += 1
  }

  $verifiedText = if ($IsVerified) { "verified" } else { "unverified" }
  $capturedAt = (Get-Date).ToUniversalTime().ToString("o")

  $content = @(
    "# $MemoryTitle",
    "",
    "- Captured: $capturedAt",
    "- Layer: $MemoryLayer",
    "- Source: $MemorySource",
    "- Verification: $verifiedText",
    "",
    "## Fact",
    "",
    $MemoryFact,
    "",
    "## Scope",
    "",
    "Applies to this Harness Engineering workspace unless a later memory entry supersedes it."
  ) -join [Environment]::NewLine

  Set-Content -LiteralPath $path -Encoding UTF8 -Value $content

  $indexPath = Join-Path $HarnessRoot "memory/index.yaml"
  if (-not (Test-Path -LiteralPath $indexPath)) {
    Ensure-Directory -Path (Split-Path -Parent $indexPath)
    Set-Content -LiteralPath $indexPath -Encoding UTF8 -Value "version: 1`nrecords:"
  }

  $relativePath = $path.Substring($HarnessRoot.Length).TrimStart("\", "/") -replace "\\", "/"
  Add-Content -LiteralPath $indexPath -Encoding UTF8 -Value "  - layer: $MemoryLayer"
  Add-Content -LiteralPath $indexPath -Encoding UTF8 -Value "    title: $MemoryTitle"
  Add-Content -LiteralPath $indexPath -Encoding UTF8 -Value "    path: $relativePath"
  Add-Content -LiteralPath $indexPath -Encoding UTF8 -Value "    verification: $verifiedText"

  Write-Output "Captured memory: $path"
}

function New-BrainstormArtifact {
  param(
    [string]$HarnessRoot,
    [string]$WorkflowId,
    [string]$BrainstormTopic,
    [string]$BrainstormGoal,
    [bool]$Overwrite
  )

  if ([string]::IsNullOrWhiteSpace($WorkflowId)) { throw "brainstorm requires -Id." }
  if ([string]::IsNullOrWhiteSpace($BrainstormTopic)) { throw "brainstorm requires -Topic." }
  if ([string]::IsNullOrWhiteSpace($BrainstormGoal)) { throw "brainstorm requires -Goal." }

  Assert-SafeId -Value $WorkflowId -Name "Id"
  $directory = Join-Path $HarnessRoot "work/brainstorms"
  Ensure-Directory -Path $directory
  $path = Join-Path $directory "$WorkflowId.md"
  if ((Test-Path -LiteralPath $path) -and -not $Overwrite) {
    throw "Brainstorm already exists: work/brainstorms/$WorkflowId.md"
  }

  $content = @(
    "# Brainstorm: $BrainstormTopic",
    "",
    "Status: active",
    "",
    "## Metadata",
    "",
    "- ID: $WorkflowId",
    "- Created: $((Get-Date).ToUniversalTime().ToString("o"))",
    "",
    "## Goal",
    "",
    $BrainstormGoal,
    "",
    "## Clarifying Questions",
    "",
    "- What is the user outcome?",
    "- What constraints are non-negotiable?",
    "- What does success prove?",
    "",
    "## Candidate Approaches",
    "",
    "- Recommended: artifact-driven workflow with explicit gates.",
    "- Alternative: skill-only guidance.",
    "- Alternative: agent orchestration-first workflow.",
    "",
    "## Decision Gate",
    "",
    "- Move to design only after the user confirms the chosen approach."
  ) -join [Environment]::NewLine

  Set-Content -LiteralPath $path -Encoding UTF8 -Value $content
  Write-Output "Created brainstorm: $path"
}

function New-DesignArtifact {
  param(
    [string]$HarnessRoot,
    [string]$WorkflowId,
    [string]$DesignDecision,
    [string]$DesignConstraints,
    [bool]$Overwrite
  )

  if ([string]::IsNullOrWhiteSpace($WorkflowId)) { throw "design requires -Id." }
  if ([string]::IsNullOrWhiteSpace($DesignDecision)) { throw "design requires -Decision." }

  Assert-SafeId -Value $WorkflowId -Name "Id"
  $directory = Join-Path $HarnessRoot "work/designs"
  Ensure-Directory -Path $directory
  $path = Join-Path $directory "$WorkflowId.md"
  if ((Test-Path -LiteralPath $path) -and -not $Overwrite) {
    throw "Design already exists: work/designs/$WorkflowId.md"
  }

  $constraintsText = if ([string]::IsNullOrWhiteSpace($DesignConstraints)) { "No explicit constraints provided." } else { $DesignConstraints }
  $content = @(
    "# Design: $WorkflowId",
    "",
    "Status: proposed",
    "",
    "## Decision",
    "",
    $DesignDecision,
    "",
    "## Constraints",
    "",
    $constraintsText,
    "",
    "## Architecture",
    "",
    "- Keep workflow artifacts separate from runtime-specific agent files.",
    "- Route runtime behavior through hooks and MCP tools.",
    "- Keep generated reports deterministic and locally verifiable.",
    "",
    "## Verification",
    "",
    "- Run scripts/validate-workflow-capabilities.ps1.",
    "- Run scripts/doctor.ps1."
  ) -join [Environment]::NewLine

  Set-Content -LiteralPath $path -Encoding UTF8 -Value $content
  Write-Output "Created design: $path"
}

function New-PlanArtifact {
  param(
    [string]$HarnessRoot,
    [string]$WorkflowId,
    [string]$DesignPath,
    [bool]$Overwrite
  )

  if ([string]::IsNullOrWhiteSpace($WorkflowId)) { throw "plan requires -Id." }
  if ([string]::IsNullOrWhiteSpace($DesignPath)) { throw "plan requires -Design." }

  Assert-SafeId -Value $WorkflowId -Name "Id"
  $resolvedDesign = if ([System.IO.Path]::IsPathRooted($DesignPath)) { $DesignPath } else { Join-Path $HarnessRoot $DesignPath }
  if (-not (Test-Path -LiteralPath $resolvedDesign)) {
    throw "Design file does not exist: $DesignPath"
  }

  $directory = Join-Path $HarnessRoot "work/plans"
  Ensure-Directory -Path $directory
  $path = Join-Path $directory "$WorkflowId.md"
  if ((Test-Path -LiteralPath $path) -and -not $Overwrite) {
    throw "Plan already exists: work/plans/$WorkflowId.md"
  }

  $content = @(
    "# Plan: $WorkflowId",
    "",
    "Status: ready",
    "",
    "## Source Design",
    "",
    $DesignPath,
    "",
    "## Tasks",
    "",
    "- [ ] Load context and confirm scope.",
    "- [ ] Implement the smallest useful slice.",
    "- [ ] Record checkpoints with evidence.",
    "- [ ] Run workflow validation.",
    "- [ ] Run full doctor validation.",
    "- [ ] Deliver with verification evidence and residual risks.",
    "",
    "## Verification",
    "",
    '```powershell',
    "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-workflow-capabilities.ps1",
    "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/doctor.ps1",
    '```'
  ) -join [Environment]::NewLine

  Set-Content -LiteralPath $path -Encoding UTF8 -Value $content
  Write-Output "Created plan: $path"
}

function Add-WorkflowCheckpoint {
  param(
    [string]$HarnessRoot,
    [string]$WorkflowId,
    [string]$CheckpointStep,
    [string]$CheckpointEvidence
  )

  if ([string]::IsNullOrWhiteSpace($WorkflowId)) { throw "checkpoint requires -Id." }
  if ([string]::IsNullOrWhiteSpace($CheckpointStep)) { throw "checkpoint requires -Step." }
  if ([string]::IsNullOrWhiteSpace($CheckpointEvidence)) { throw "checkpoint requires -Evidence." }

  Assert-SafeId -Value $WorkflowId -Name "Id"
  $taskPath = Join-Path $HarnessRoot "work/active/$WorkflowId.md"
  if (-not (Test-Path -LiteralPath $taskPath)) {
    throw "Active task does not exist: work/active/$WorkflowId.md"
  }

  $timestamp = (Get-Date).ToUniversalTime().ToString("o")
  $entry = @(
    "",
    "## Checkpoint $timestamp",
    "",
    "- Step: $CheckpointStep",
    "- Evidence: $CheckpointEvidence"
  ) -join [Environment]::NewLine
  Add-Content -LiteralPath $taskPath -Encoding UTF8 -Value $entry

  $logPath = Join-Path $HarnessRoot "work/implementation-log.md"
  if (-not (Test-Path -LiteralPath $logPath)) {
    Set-Content -LiteralPath $logPath -Encoding UTF8 -Value "# Implementation Log"
  }
  Add-Content -LiteralPath $logPath -Encoding UTF8 -Value (@(
    "",
    "## $timestamp",
    "",
    "- Task: $WorkflowId",
    "- Step: $CheckpointStep",
    "- Evidence: $CheckpointEvidence"
  ) -join [Environment]::NewLine)

  Write-Output "Recorded checkpoint: $WorkflowId"
}

function Get-WorkflowStatus {
  param(
    [string]$HarnessRoot,
    [string]$WorkflowId
  )

  if ([string]::IsNullOrWhiteSpace($WorkflowId)) { throw "workflow-status requires -Id." }
  Assert-SafeId -Value $WorkflowId -Name "Id"

  $brainstorm = "work/brainstorms/$WorkflowId.md"
  $designFile = "work/designs/$WorkflowId.md"
  $planFile = "work/plans/$WorkflowId.md"
  $task = "work/active/$WorkflowId.md"
  $logPath = Join-Path $HarnessRoot "work/implementation-log.md"
  $checkpointCount = 0
  if (Test-Path -LiteralPath $logPath) {
    $checkpointCount = @(Select-String -LiteralPath $logPath -Pattern "- Task: $WorkflowId" -SimpleMatch).Count
  }

  return [ordered]@{
    id = $WorkflowId
    brainstorm = [ordered]@{ path = $brainstorm; exists = Test-Path -LiteralPath (Join-Path $HarnessRoot $brainstorm) }
    design = [ordered]@{ path = $designFile; exists = Test-Path -LiteralPath (Join-Path $HarnessRoot $designFile) }
    plan = [ordered]@{ path = $planFile; exists = Test-Path -LiteralPath (Join-Path $HarnessRoot $planFile) }
    task = [ordered]@{ path = $task; exists = Test-Path -LiteralPath (Join-Path $HarnessRoot $task) }
    checkpoints = $checkpointCount
  }
}

$resolvedRoot = Resolve-Root -Path $Root

switch ($Command) {
  "status" {
    $status = Get-HarnessStatus -HarnessRoot $resolvedRoot
    if ($Json) {
      $status | ConvertTo-Json -Compress
    } else {
      Write-Output "Root: $($status.root)"
      Write-Output "Active tasks: $($status.activeTasksCount)"
      Write-Output "Memory entries: $($status.memoryEntriesCount)"
    }
  }
  "new-task" {
    New-HarnessTask -HarnessRoot $resolvedRoot -TaskId $Id -TaskTitle $Title -TaskFlow $Flow -TaskGoal $Goal -VerifyCommand $Verify -Overwrite $Force.IsPresent
  }
  "capture-memory" {
    Add-HarnessMemory -HarnessRoot $resolvedRoot -MemoryLayer $Layer -MemoryTitle $Title -MemoryFact $Fact -MemorySource $Source -IsVerified $Verified.IsPresent
  }
  "brainstorm" {
    New-BrainstormArtifact -HarnessRoot $resolvedRoot -WorkflowId $Id -BrainstormTopic $Topic -BrainstormGoal $Goal -Overwrite $Force.IsPresent
  }
  "design" {
    New-DesignArtifact -HarnessRoot $resolvedRoot -WorkflowId $Id -DesignDecision $Decision -DesignConstraints $Constraints -Overwrite $Force.IsPresent
  }
  "plan" {
    New-PlanArtifact -HarnessRoot $resolvedRoot -WorkflowId $Id -DesignPath $Design -Overwrite $Force.IsPresent
  }
  "checkpoint" {
    Add-WorkflowCheckpoint -HarnessRoot $resolvedRoot -WorkflowId $Id -CheckpointStep $Step -CheckpointEvidence $Evidence
  }
  "workflow-status" {
    $workflowStatus = Get-WorkflowStatus -HarnessRoot $resolvedRoot -WorkflowId $Id
    if ($Json) {
      $workflowStatus | ConvertTo-Json -Compress
    } else {
      Write-Output "Workflow: $($workflowStatus.id)"
      Write-Output "Brainstorm: $($workflowStatus.brainstorm.exists)"
      Write-Output "Design: $($workflowStatus.design.exists)"
      Write-Output "Plan: $($workflowStatus.plan.exists)"
      Write-Output "Task: $($workflowStatus.task.exists)"
      Write-Output "Checkpoints: $($workflowStatus.checkpoints)"
    }
  }
}
