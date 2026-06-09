param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$outputDir = Join-Path $rootPath "wiki/architecture"
if (-not (Test-Path -LiteralPath $outputDir)) {
  New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

$ignored = @(".git", "node_modules")
$topDirs = @(Get-ChildItem -LiteralPath $rootPath -Directory | Where-Object { $_.Name -notin $ignored } | Sort-Object Name)
$files = @(Get-ChildItem -LiteralPath $rootPath -File | Sort-Object Name)

$lines = @(
  "# Code Structure Map",
  "",
  "- Generated: $((Get-Date).ToUniversalTime().ToString("o"))",
  "- Source: scripts/generate-code-map.ps1",
  "",
  "## Top-level Files",
  ""
)

if ($files.Count -eq 0) {
  $lines += "- No top-level files found."
} else {
  foreach ($file in $files) {
    $lines += "- $($file.Name)"
  }
}

$lines += @(
  "",
  "## Top-level Directories",
  ""
)

foreach ($dir in $topDirs) {
  $count = @(Get-ChildItem -LiteralPath $dir.FullName -File -Recurse -ErrorAction SilentlyContinue).Count
  $lines += "- $($dir.Name) ($count files)"
}

$lines += @(
  "",
  "## Mermaid",
  "",
  '```mermaid',
  "flowchart TD",
  "  root[HarnessEngineering]"
)

foreach ($dir in $topDirs) {
  $node = ($dir.Name -replace "[^A-Za-z0-9]", "_")
  if ([string]::IsNullOrWhiteSpace($node)) {
    $node = "dir"
  }
  $lines += "  root --> $node[$($dir.Name)]"
}

$lines += '```'

$outputPath = Join-Path $outputDir "code-map.md"
Set-Content -LiteralPath $outputPath -Encoding UTF8 -Value ($lines -join [Environment]::NewLine)

Write-Output "generate-code-map: OK"

