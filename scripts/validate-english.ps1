$ErrorActionPreference = "Stop"

$rootPath = (Resolve-Path -LiteralPath ".").Path
$ignoredDirectories = @(
  ".git",
  "node_modules"
)

$textExtensions = @(
  ".md",
  ".ps1",
  ".js",
  ".json",
  ".yaml",
  ".yml",
  ".txt"
)

$violations = @()
$files = @(Get-ChildItem -LiteralPath $rootPath -File -Recurse | Where-Object {
  $relative = $_.FullName.Substring($rootPath.Length).TrimStart("\", "/") -replace "\\", "/"
  $directoryParts = $relative -split "/"
  $hasIgnoredDirectory = $false
  foreach ($part in $directoryParts) {
    if ($ignoredDirectories -contains $part) {
      $hasIgnoredDirectory = $true
      break
    }
  }

  (-not $hasIgnoredDirectory) -and ($textExtensions -contains $_.Extension)
})

foreach ($file in $files) {
  try {
    $lines = Get-Content -LiteralPath $file.FullName -ErrorAction Stop
  } catch {
    continue
  }

  for ($index = 0; $index -lt $lines.Count; $index += 1) {
    if ($lines[$index] -match "\p{IsCJKUnifiedIdeographs}") {
      $relative = $file.FullName.Substring($rootPath.Length).TrimStart("\", "/") -replace "\\", "/"
      $violations += "${relative}:$($index + 1)"
    }
  }
}

if ($violations.Count -gt 0) {
  throw "Non-English CJK text found: $($violations -join ', ')"
}

Write-Output "validate-english: OK"
