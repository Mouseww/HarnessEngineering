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
$settings = Get-Content -LiteralPath ".claude/settings.json" -Raw | ConvertFrom-Json
$settingsText = Get-Content -LiteralPath ".claude/settings.json" -Raw

Assert-True -Condition ($settingsText -like "*auto-maintenance.ps1*") -Message "Claude Code settings must trigger auto-maintenance hook."
Assert-True -Condition (Test-Path -LiteralPath ".claude/hooks/auto-maintenance.ps1") -Message "Missing auto-maintenance hook."
Assert-True -Condition (Test-Path -LiteralPath "scripts/update-memory-index.ps1") -Message "Missing memory improvement script."
Assert-True -Condition (Test-Path -LiteralPath "scripts/generate-code-map.ps1") -Message "Missing code map script."
Assert-True -Condition (Test-Path -LiteralPath "scripts/review-changes.ps1") -Message "Missing review script."

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("harness-automation-" + [Guid]::NewGuid().ToString("N"))
$dirs = @(
  "memory/team",
  "memory/project",
  "memory/agents/claude-code",
  "wiki/architecture",
  "work/reviews",
  "scripts",
  "protocols",
  "core/checklists",
  "mcp/harness-server"
)

foreach ($dir in $dirs) {
  New-Item -ItemType Directory -Force -Path (Join-Path $testRoot $dir) | Out-Null
}

Set-Content -LiteralPath (Join-Path $testRoot "harness.yaml") -Encoding UTF8 -Value "version: 1`nname: test"
Set-Content -LiteralPath (Join-Path $testRoot "memory/team/engineering.md") -Encoding UTF8 -Value "# Engineering Memory`n`n## Fact`n`nUse validation before delivery."
Set-Content -LiteralPath (Join-Path $testRoot "protocols/context-loading.md") -Encoding UTF8 -Value "# Context Loading"
$exampleScript = Join-Path $testRoot "scripts/example.ps1"
Set-Content -LiteralPath $exampleScript -Encoding UTF8 -Value 'Assert-True -Condition (($settings.permissions.deny -join "`n") -like "*git push*") -Message "Installer did not merge dangerous operation deny rules."'
Set-Content -LiteralPath (Join-Path $testRoot "mcp/harness-server/server.js") -Encoding UTF8 -Value "console.log('server');"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot "scripts/update-memory-index.ps1") -Root $testRoot
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot "scripts/generate-code-map.ps1") -Root $testRoot
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot "scripts/review-changes.ps1") -Root $testRoot
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot ".claude/hooks/auto-maintenance.ps1") -Root $testRoot

$memoryIndex = Join-Path $testRoot "memory/auto-index.md"
$memoryHealth = Join-Path $testRoot "memory/health.md"
$codeMap = Join-Path $testRoot "wiki/architecture/code-map.md"
$review = Join-Path $testRoot "work/reviews/latest-review.md"

Assert-True -Condition (Test-Path -LiteralPath $memoryIndex) -Message "Expected generated memory auto-index."
Assert-True -Condition (Test-Path -LiteralPath $memoryHealth) -Message "Expected generated memory health report."
Assert-True -Condition (Test-Path -LiteralPath $codeMap) -Message "Expected generated code map."
Assert-True -Condition (Test-Path -LiteralPath $review) -Message "Expected generated review report."

$codeMapText = Get-Content -LiteralPath $codeMap -Raw
$reviewText = Get-Content -LiteralPath $review -Raw
$memoryText = Get-Content -LiteralPath $memoryIndex -Raw

Assert-True -Condition ($codeMapText -like "*Mermaid*") -Message "Code map should include a Mermaid section."
Assert-True -Condition ($reviewText -like "*Review Summary*") -Message "Review report should include summary."
Assert-True -Condition ($reviewText -notlike "*unconfirmed git push*") -Message "Review report should not flag a quoted git push policy string."
Assert-True -Condition ($memoryText -like "*engineering.md*") -Message "Memory auto-index should include memory file."

Set-Content -LiteralPath $exampleScript -Encoding UTF8 -Value "git push origin main"
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot "scripts/review-changes.ps1") -Root $testRoot
$dangerReviewText = Get-Content -LiteralPath $review -Raw
Assert-True -Condition ($dangerReviewText -like "*unconfirmed git push*") -Message "Review report should flag a real git push command."

Write-Output "validate-automation-hooks: OK"
