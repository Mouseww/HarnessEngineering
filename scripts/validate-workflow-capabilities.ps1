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
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-workflow-" + [Guid]::NewGuid().ToString("N"))

$dirs = @(
  "flows",
  "work/active",
  "work/brainstorms",
  "work/designs",
  "work/plans",
  "work/reviews",
  "memory/team",
  "memory/project",
  "memory/agents/claude-code",
  "wiki/architecture"
)

foreach ($dir in $dirs) {
  New-Item -ItemType Directory -Force -Path (Join-Path $testRoot $dir) | Out-Null
}

Set-Content -LiteralPath (Join-Path $testRoot "flows/feature-development.md") -Encoding UTF8 -Value "# Feature Development Flow"
Set-Content -LiteralPath (Join-Path $testRoot "memory/index.yaml") -Encoding UTF8 -Value "version: 1`nentries: []"

$harness = Join-Path $repoRoot "scripts/harness.ps1"

powershell -NoProfile -ExecutionPolicy Bypass -File $harness brainstorm -Root $testRoot -Id "wf-alpha" -Topic "Improve workflow discipline" -Goal "Create actionable workflow artifacts"
powershell -NoProfile -ExecutionPolicy Bypass -File $harness design -Root $testRoot -Id "wf-alpha" -Decision "Use artifact-driven workflow gates" -Constraints "No external API calls"
powershell -NoProfile -ExecutionPolicy Bypass -File $harness plan -Root $testRoot -Id "wf-alpha" -Design "work/designs/wf-alpha.md"
powershell -NoProfile -ExecutionPolicy Bypass -File $harness new-task -Root $testRoot -Id "wf-alpha" -Title "Implement workflow discipline" -Flow "feature-development" -Goal "Use checkpoints to track implementation" -Verify "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/doctor.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $harness checkpoint -Root $testRoot -Id "wf-alpha" -Step "Created workflow artifacts" -Evidence "validate-workflow-capabilities.ps1"

$brainstormPath = Join-Path $testRoot "work/brainstorms/wf-alpha.md"
$designPath = Join-Path $testRoot "work/designs/wf-alpha.md"
$planPath = Join-Path $testRoot "work/plans/wf-alpha.md"
$logPath = Join-Path $testRoot "work/implementation-log.md"

Assert-True -Condition (Test-Path -LiteralPath $brainstormPath) -Message "Expected brainstorm artifact."
Assert-True -Condition (Test-Path -LiteralPath $designPath) -Message "Expected design artifact."
Assert-True -Condition (Test-Path -LiteralPath $planPath) -Message "Expected plan artifact."
Assert-True -Condition (Test-Path -LiteralPath $logPath) -Message "Expected implementation log."

$statusJson = powershell -NoProfile -ExecutionPolicy Bypass -File $harness workflow-status -Root $testRoot -Id "wf-alpha" -Json
$status = $statusJson | ConvertFrom-Json
Assert-True -Condition ($status.brainstorm.exists -and $status.design.exists -and $status.plan.exists -and $status.task.exists) -Message "workflow-status should report all artifacts."
Assert-True -Condition ($status.checkpoints -ge 1) -Message "workflow-status should report checkpoint count."

$guidanceInput = '{"prompt":"Design a new feature and create an implementation plan"}'
$guidanceOutput = $guidanceInput | powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot ".claude/hooks/workflow-guidance.ps1") -Root $testRoot
Assert-True -Condition (($guidanceOutput -join "`n") -like "*Harness Request Router*") -Message "Expected workflow guidance output."
Assert-True -Condition (($guidanceOutput -join "`n") -like "*design*") -Message "Expected design guidance."
Assert-True -Condition (($guidanceOutput -join "`n") -like "*plan*") -Message "Expected plan guidance."

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot "scripts/update-workflow-gates.ps1") -Root $testRoot
$gatePath = Join-Path $testRoot "work/workflow-gates.md"
Assert-True -Condition (Test-Path -LiteralPath $gatePath) -Message "Expected workflow gate report."
Assert-True -Condition ((Get-Content -LiteralPath $gatePath -Raw) -like "*wf-alpha*") -Message "Expected workflow gate report to mention task id."

$mcpOutput = node "mcp/harness-server/server.js" --self-test-workflow
if ($LASTEXITCODE -ne 0) {
  throw "Harness MCP workflow self-test failed."
}
Assert-True -Condition (($mcpOutput -join "`n") -like "*Harness MCP workflow self-test passed*") -Message "Expected MCP workflow self-test confirmation."

Write-Output "validate-workflow-capabilities: OK"
