param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$outputDir = Join-Path $rootPath "work/reviews"
if (-not (Test-Path -LiteralPath $outputDir)) {
  New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

$reviewTargets = @()
$gitDir = Join-Path $rootPath ".git"
if (Test-Path -LiteralPath $gitDir) {
  $status = git -C $rootPath status --porcelain
  foreach ($line in $status) {
    if ($line.Length -ge 4) {
      $path = $line.Substring(3).Trim()
      if (-not [string]::IsNullOrWhiteSpace($path)) {
        $reviewTargets += $path
      }
    }
  }
} else {
  $reviewTargets = @(Get-ChildItem -LiteralPath $rootPath -File -Recurse | Where-Object {
    $_.FullName -notmatch "\\.git\\" -and $_.FullName -notmatch "\\node_modules\\"
  } | ForEach-Object {
    $_.FullName.Substring($rootPath.Length).TrimStart("\", "/") -replace "\\", "/"
  })
}

$reviewTargets = @($reviewTargets | Sort-Object -Unique)
$patterns = @(
  @{ Name = "destructive git reset"; Pattern = "git\s+reset\s+--hard"; Severity = "P1"; CodeOnly = $true },
  @{ Name = "unconfirmed git push"; Pattern = "git\s+push\b"; Severity = "P1"; CodeOnly = $true },
  @{ Name = "recursive delete"; Pattern = "Remove-Item\s+.+-Recurse|\brm\s+-rf\b"; Severity = "P1"; CodeOnly = $true },
  @{ Name = "PowerShell incompatible ConvertFrom-Json depth"; Pattern = "ConvertFrom-Json\s+-Depth"; Severity = "P2"; CodeOnly = $true },
  @{ Name = "unfinished placeholder"; Pattern = "\bTODO\b|\bTBD\b"; Severity = "P3"; CodeOnly = $false }
)

$codeExtensions = @(".ps1", ".js", ".ts", ".json", ".yaml", ".yml", ".sh", ".bat", ".cmd", ".py", ".cs", ".java", ".go", ".rs")

function Remove-QuotedSegments {
  param([Parameter(Mandatory = $true)][string]$Line)

  $withoutSingleQuoted = [regex]::Replace($Line, "'(?:''|[^'])*'", "''")
  return [regex]::Replace($withoutSingleQuoted, '"(?:""|[^"])*"', '""')
}

function Test-ReviewPattern {
  param(
    [Parameter(Mandatory = $true)][string]$Content,
    [Parameter(Mandatory = $true)][string]$Pattern,
    [Parameter(Mandatory = $true)][bool]$CodeOnly
  )

  if (-not $CodeOnly) {
    return $Content -match $Pattern
  }

  foreach ($line in ($Content -split "\r?\n")) {
    $trimmed = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
      continue
    }
    if ($trimmed.StartsWith("#") -or $trimmed.StartsWith("//")) {
      continue
    }

    $candidate = Remove-QuotedSegments -Line $line
    if ($candidate -match $Pattern) {
      return $true
    }
  }

  return $false
}

$findings = @()
foreach ($relative in $reviewTargets) {
  $absolute = Join-Path $rootPath $relative
  if (-not (Test-Path -LiteralPath $absolute)) {
    continue
  }
  if ((Get-Item -LiteralPath $absolute).PSIsContainer) {
    continue
  }
  try {
    $content = Get-Content -LiteralPath $absolute -Raw -ErrorAction Stop
  } catch {
    continue
  }
  $extension = [System.IO.Path]::GetExtension($absolute)
  $isCodeLike = $codeExtensions -contains $extension
  foreach ($item in $patterns) {
    if ($item.CodeOnly -and -not $isCodeLike) {
      continue
    }
    if (Test-ReviewPattern -Content $content -Pattern $item.Pattern -CodeOnly $item.CodeOnly) {
      $findings += [ordered]@{
        severity = $item.Severity
        path = $relative
        issue = $item.Name
      }
    }
  }
}

$lines = @(
  "# Automated Code Review",
  "",
  "- Generated: $((Get-Date).ToUniversalTime().ToString("o"))",
  "- Source: scripts/review-changes.ps1",
  "",
  "## Review Summary",
  "",
  "- files reviewed: $($reviewTargets.Count)",
  "- findings: $($findings.Count)",
  "",
  "## Findings",
  ""
)

if ($findings.Count -eq 0) {
  $lines += "- No deterministic findings."
} else {
  foreach ($finding in $findings) {
    $lines += "- [$($finding.severity)] $($finding.path): $($finding.issue)"
  }
}

$lines += @(
  "",
  "## Scope",
  "",
  "This report is deterministic and pattern-based. It does not replace human or model code review."
)

$outputPath = Join-Path $outputDir "latest-review.md"
Set-Content -LiteralPath $outputPath -Encoding UTF8 -Value ($lines -join [Environment]::NewLine)

Write-Output "review-changes: OK"
