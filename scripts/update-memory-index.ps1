param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$memoryRoot = Join-Path $rootPath "memory"

if (-not (Test-Path -LiteralPath $memoryRoot)) {
  New-Item -ItemType Directory -Force -Path $memoryRoot | Out-Null
}

$files = @(Get-ChildItem -LiteralPath $memoryRoot -Filter "*.md" -File -Recurse | Where-Object {
  $_.Name -notin @("index.md", "auto-index.md", "health.md")
})

$lines = @(
  "# Memory Auto Index",
  "",
  "- Generated: $((Get-Date).ToUniversalTime().ToString("o"))",
  "- Source: scripts/update-memory-index.ps1",
  "",
  "## Entries",
  ""
)

if ($files.Count -eq 0) {
  $lines += "- No memory entries found."
} else {
  foreach ($file in ($files | Sort-Object FullName)) {
    $relative = $file.FullName.Substring($rootPath.Length).TrimStart("\", "/") -replace "\\", "/"
    $title = (Get-Content -LiteralPath $file.FullName -TotalCount 1) -replace "^#\s*", ""
    if ([string]::IsNullOrWhiteSpace($title)) {
      $title = $file.BaseName
    }
    $lines += "- [$title]($relative) - $relative"
  }
}

$indexPath = Join-Path $memoryRoot "auto-index.md"
Set-Content -LiteralPath $indexPath -Encoding UTF8 -Value ($lines -join [Environment]::NewLine)

$expected = @("memory/team", "memory/project", "memory/agents")
$healthLines = @(
  "# Memory Health",
  "",
  "- Generated: $((Get-Date).ToUniversalTime().ToString("o"))",
  "",
  "## Checks",
  ""
)

foreach ($path in $expected) {
  $absolute = Join-Path $rootPath $path
  $exists = Test-Path -LiteralPath $absolute
  $status = if ($exists) { "OK" } else { "Missing" }
  $healthLines += "- ${path}: $status"
}

$healthLines += "- entries: $($files.Count)"

$healthLines += @(
  "",
  "## Recommendations",
  ""
)

if ($files.Count -eq 0) {
  $healthLines += "- Capture reusable decisions with scripts/harness.ps1 capture-memory after meaningful work."
} else {
  $healthLines += "- Review memory/auto-index.md before delivery to confirm reusable facts are discoverable."
}

$healthPath = Join-Path $memoryRoot "health.md"
Set-Content -LiteralPath $healthPath -Encoding UTF8 -Value ($healthLines -join [Environment]::NewLine)

Write-Output "update-memory-index: OK"
