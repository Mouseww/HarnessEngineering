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
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-router-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path (Join-Path $testRoot "work/request-routing") | Out-Null

$router = Join-Path $repoRoot "scripts/route-request.ps1"

$bugfixJson = powershell -NoProfile -ExecutionPolicy Bypass -File $router -Root $testRoot -Prompt "Fix login API error and add regression verification" -Json
$bugfix = $bugfixJson | ConvertFrom-Json
Assert-True -Condition ($bugfix.flow -eq "bugfix") -Message "Expected bugfix flow for fix/error request."
Assert-True -Condition (($bugfix.stages -join ",") -like "*reproduce*") -Message "Bugfix route should include reproduce stage."
Assert-True -Condition (($bugfix.skills -join ",") -like "*implement-safely*") -Message "Bugfix route should include implement-safely skill."
Assert-True -Condition (($bugfix.nextCommand) -like "*scripts/harness.ps1 brainstorm*") -Message "Route should include next harness command."

$featureJson = powershell -NoProfile -ExecutionPolicy Bypass -File $router -Root $testRoot -Prompt "Design a new MCP tool and create an implementation plan" -Json
$feature = $featureJson | ConvertFrom-Json
Assert-True -Condition ($feature.flow -eq "feature-development") -Message "Expected feature-development flow for design/plan request."
Assert-True -Condition (($feature.stages -join ",") -like "*design*") -Message "Feature route should include design stage."
Assert-True -Condition (($feature.skills -join ",") -like "*mcp-governance*") -Message "MCP request should include mcp-governance skill."

$neutralJson = powershell -NoProfile -ExecutionPolicy Bypass -File $router -Root $testRoot -Prompt "Route user requests to suitable flow stages skills artifacts and next command" -Json
$neutral = $neutralJson | ConvertFrom-Json
Assert-True -Condition ($neutral.flow -eq "feature-development") -Message "The word stages must not trigger release through tag substring matching."

$releaseJson = powershell -NoProfile -ExecutionPolicy Bypass -File $router -Root $testRoot -Prompt "Release v1.2.0 to production and prepare rollback notes" -Json
$release = $releaseJson | ConvertFrom-Json
Assert-True -Condition ($release.flow -eq "release") -Message "Expected release flow."
Assert-True -Condition (($release.skills -join ",") -like "*release-readiness*") -Message "Release route should include release-readiness skill."

$incidentJson = powershell -NoProfile -ExecutionPolicy Bypass -File $router -Root $testRoot -Prompt "Production service is unavailable and all users cannot log in" -Json
$incident = $incidentJson | ConvertFrom-Json
Assert-True -Condition ($incident.flow -eq "incident") -Message "Expected incident flow."
Assert-True -Condition (($incident.stages -join ",") -like "*stabilize*") -Message "Incident route should include stabilize stage."

$latestJsonPath = Join-Path $testRoot "work/request-routing/latest.json"
$latestMarkdownPath = Join-Path $testRoot "work/request-routing/latest.md"
Assert-True -Condition (Test-Path -LiteralPath $latestJsonPath) -Message "Expected latest request routing JSON."
Assert-True -Condition (Test-Path -LiteralPath $latestMarkdownPath) -Message "Expected latest request routing Markdown."

$guidanceInput = '{"prompt":"Fix CI failure and create a plan"}'
$guidanceOutput = $guidanceInput | powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot ".claude/hooks/workflow-guidance.ps1") -Root $testRoot
Assert-True -Condition (($guidanceOutput -join "`n") -like "*Harness Request Router*") -Message "Workflow guidance should use request router."
Assert-True -Condition (($guidanceOutput -join "`n") -like "*bugfix*") -Message "Workflow guidance should include routed flow."

$mcpOutput = node "mcp/harness-server/server.js" --self-test-router
if ($LASTEXITCODE -ne 0) {
  throw "Harness MCP router self-test failed."
}
Assert-True -Condition (($mcpOutput -join "`n") -like "*Harness MCP router self-test passed*") -Message "Expected MCP router self-test confirmation."

Write-Output "validate-flow-router: OK"
