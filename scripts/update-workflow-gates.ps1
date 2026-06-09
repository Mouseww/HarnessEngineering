param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$workRoot = Join-Path $rootPath "work"
if (-not (Test-Path -LiteralPath $workRoot)) {
  New-Item -ItemType Directory -Force -Path $workRoot | Out-Null
}

function Get-Names {
  param(
    [string]$Directory
  )

  if (-not (Test-Path -LiteralPath $Directory)) {
    return @()
  }

  return @(Get-ChildItem -LiteralPath $Directory -Filter "*.md" -File | ForEach-Object { $_.BaseName } | Sort-Object -Unique)
}

$brainstorms = Get-Names -Directory (Join-Path $workRoot "brainstorms")
$designs = Get-Names -Directory (Join-Path $workRoot "designs")
$plans = Get-Names -Directory (Join-Path $workRoot "plans")
$tasks = Get-Names -Directory (Join-Path $workRoot "active")
$allIds = @($brainstorms + $designs + $plans + $tasks | Sort-Object -Unique)

$lines = @(
  "# Workflow Gates",
  "",
  "- Generated: $((Get-Date).ToUniversalTime().ToString("o"))",
  "- Source: scripts/update-workflow-gates.ps1",
  "",
  "## Summary",
  "",
  "- brainstorms: $($brainstorms.Count)",
  "- designs: $($designs.Count)",
  "- plans: $($plans.Count)",
  "- active tasks: $($tasks.Count)",
  "",
  "## Gate Matrix",
  ""
)

if ($allIds.Count -eq 0) {
  $lines += "- No workflow artifacts found."
} else {
  $lines += "| ID | Brainstorm | Design | Plan | Active Task |"
  $lines += "| --- | --- | --- | --- | --- |"
  foreach ($id in $allIds) {
    $hasBrainstorm = if ($brainstorms -contains $id) { "yes" } else { "no" }
    $hasDesign = if ($designs -contains $id) { "yes" } else { "no" }
    $hasPlan = if ($plans -contains $id) { "yes" } else { "no" }
    $hasTask = if ($tasks -contains $id) { "yes" } else { "no" }
    $lines += "| $id | $hasBrainstorm | $hasDesign | $hasPlan | $hasTask |"
  }
}

$outputPath = Join-Path $workRoot "workflow-gates.md"
Set-Content -LiteralPath $outputPath -Encoding UTF8 -Value ($lines -join [Environment]::NewLine)

Write-Output "update-workflow-gates: OK"

