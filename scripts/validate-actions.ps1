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
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-actions-" + [Guid]::NewGuid().ToString("N"))

$dirs = @(
  "flows",
  "work/active",
  "work/done",
  "work/archived",
  "memory/team",
  "memory/project",
  "memory/agents/claude-code"
)

foreach ($dir in $dirs) {
  New-Item -ItemType Directory -Force -Path (Join-Path $testRoot $dir) | Out-Null
}

Set-Content -LiteralPath (Join-Path $testRoot "flows/feature-development.md") -Encoding UTF8 -Value "# Feature Development Flow"
Set-Content -LiteralPath (Join-Path $testRoot "memory/index.yaml") -Encoding UTF8 -Value "version: 1`nentries: []"

$harnessScript = Join-Path $repoRoot "scripts/harness.ps1"

$initialStatus = powershell -NoProfile -ExecutionPolicy Bypass -File $harnessScript status -Root $testRoot -Json
$initial = $initialStatus | ConvertFrom-Json
Assert-True -Condition ($initial.activeTasksCount -eq 0) -Message "Expected no active tasks in fresh test root."

powershell -NoProfile -ExecutionPolicy Bypass -File $harnessScript new-task -Root $testRoot -Id "task-alpha" -Title "Build functional harness actions" -Flow "feature-development" -Goal "Prove Harness can create actionable task files." -Verify "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/doctor.ps1"

$taskPath = Join-Path $testRoot "work/active/task-alpha.md"
Assert-True -Condition (Test-Path -LiteralPath $taskPath) -Message "Expected new-task to create task file."

$taskText = Get-Content -LiteralPath $taskPath -Raw
Assert-True -Condition ($taskText -like "*Status: active*") -Message "Expected task file to contain active status."
Assert-True -Condition ($taskText -like "*powershell -NoProfile -ExecutionPolicy Bypass -File scripts/doctor.ps1*") -Message "Expected task file to contain verification command."

powershell -NoProfile -ExecutionPolicy Bypass -File $harnessScript capture-memory -Root $testRoot -Layer project -Title "Harness action validation" -Fact "Harness actions create task files and memory records." -Source "scripts/validate-actions.ps1" -Verified

$memoryFiles = Get-ChildItem -LiteralPath (Join-Path $testRoot "memory/project") -Filter "*.md"
Assert-True -Condition ($memoryFiles.Count -eq 1) -Message "Expected capture-memory to create one project memory file."

$memoryText = Get-Content -LiteralPath $memoryFiles[0].FullName -Raw
Assert-True -Condition ($memoryText -like "*Harness actions create task files and memory records.*") -Message "Expected memory file to contain captured fact."

$updatedStatus = powershell -NoProfile -ExecutionPolicy Bypass -File $harnessScript status -Root $testRoot -Json
$status = $updatedStatus | ConvertFrom-Json
Assert-True -Condition ($status.activeTasksCount -eq 1) -Message "Expected one active task after new-task."
Assert-True -Condition ($status.memoryEntriesCount -ge 1) -Message "Expected at least one memory entry after capture-memory."

$mcpOutput = node "mcp/harness-server/server.js" --self-test-actions
if ($LASTEXITCODE -ne 0) {
  throw "Harness MCP action self-test failed."
}
Assert-True -Condition (($mcpOutput -join "`n") -like "*Harness MCP action self-test passed*") -Message "Expected MCP action self-test confirmation."

Write-Output "validate-actions: OK"
