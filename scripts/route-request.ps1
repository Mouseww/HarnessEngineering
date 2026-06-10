param(
  [string]$Root = ".",
  [string]$Prompt,
  [switch]$Json,
  [switch]$NoWrite
)

$ErrorActionPreference = "Stop"

function Resolve-HarnessRoot {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }

  return (Resolve-Path -LiteralPath $Path).Path
}

function Resolve-RequestedRoot {
  param([string]$Path)

  if ($Path -ne "." -or [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    return $Path
  }

  $scriptRuntimeRoot = Join-Path $PSScriptRoot ".."
  if (Test-Path -LiteralPath (Join-Path $scriptRuntimeRoot "harness.yaml")) {
    return $scriptRuntimeRoot
  }

  return $Path
}

function Get-PromptText {
  param([string]$ExplicitPrompt)

  if (-not [string]::IsNullOrWhiteSpace($ExplicitPrompt)) {
    return $ExplicitPrompt
  }

  $stdin = [Console]::In.ReadToEnd()
  if ([string]::IsNullOrWhiteSpace($stdin)) {
    throw "route-request requires -Prompt or stdin."
  }

  try {
    $payload = $stdin | ConvertFrom-Json
    if ($payload.prompt) {
      return [string]$payload.prompt
    }
  } catch {
    return $stdin
  }

  return $stdin
}

function New-RouteId {
  param([string]$Text)

  $slug = $Text.ToLowerInvariant() -replace "[^a-z0-9]+", "-"
  $slug = $slug.Trim("-")
  if ($slug.Length -gt 36) {
    $slug = $slug.Substring(0, 36).Trim("-")
  }
  if ([string]::IsNullOrWhiteSpace($slug)) {
    $slug = "request"
  }
  return "$slug-$((Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss"))"
}

function Test-Pattern {
  param(
    [string]$Text,
    [string]$Pattern
  )

  return [System.Text.RegularExpressions.Regex]::IsMatch($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

function Add-Unique {
  param(
    [System.Collections.Generic.List[string]]$List,
    [string[]]$Values
  )

  foreach ($value in $Values) {
    if (-not $List.Contains($value)) {
      $List.Add($value)
    }
  }
}

function Get-HarnessScriptCommandPath {
  param([string]$HarnessRoot)

  $current = (Get-Location).Path.TrimEnd("\", "/")
  $normalizedHarnessRoot = $HarnessRoot.TrimEnd("\", "/")
  $scriptPath = Join-Path $normalizedHarnessRoot "scripts/harness.ps1"

  if ($normalizedHarnessRoot -eq $current) {
    return "scripts/harness.ps1"
  }

  $prefix = $current + [System.IO.Path]::DirectorySeparatorChar
  if ($normalizedHarnessRoot.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    $relativeHarnessRoot = $normalizedHarnessRoot.Substring($prefix.Length) -replace "\\", "/"
    return "$relativeHarnessRoot/scripts/harness.ps1"
  }

  return ($scriptPath -replace "\\", "/")
}

function Get-Route {
  param(
    [string]$Text,
    [string]$HarnessRoot
  )

  $incidentPattern = "incident|outage|unavailable|down|production service|all users|prod.*fail|\u7ebf\u4e0a|\u4e0d\u53ef\u7528|\u6545\u969c|\u62a5\u8b66|\u751f\u4ea7"
  $releasePattern = "release|deploy|deployment|publish|rollback|version|\btag\b|\u53d1\u5e03|\u90e8\u7f72|\u4e0a\u7ebf|\u56de\u6eda"
  $bugfixPattern = "fix|bug|error|fail|failure|failing|exception|broken|regression|\u4fee\u590d|\u62a5\u9519|\u9519\u8bef|\u5931\u8d25|\u95ee\u9898"
  $refactorPattern = "refactor|cleanup|clean up|restructure|simplify|architecture improvement|\u91cd\u6784|\u6e05\u7406|\u4f18\u5316"
  $knowledgePattern = "memory|wiki|document|documentation|docs|knowledge|capture|summary|\u8bb0\u5fc6|\u77e5\u8bc6|\u6587\u6863|\u603b\u7ed3"
  $reviewFeedbackPattern = "review feedback|review comments|requested changes|address comments|handle review|code review feedback|\u8bc4\u5ba1\u53cd\u9988|\u5ba1\u67e5\u610f\u89c1|\u4fee\u6539\u610f\u89c1"
  $reviewRequestPattern = "request review|code review|review my changes|review this|please review|\u4ee3\u7801\u8bc4\u5ba1|\u8bf7\u8bc4\u5ba1|\u8bf7\u5ba1\u67e5"
  $mcpPattern = "\bmcp\b|model context protocol"

  $flow = "feature-development"
  $reason = "Default route for new or changed behavior."

  if (Test-Pattern -Text $Text -Pattern $reviewFeedbackPattern) {
    $flow = "review-feedback"
    $reason = "Request describes code review feedback or requested changes."
  } elseif (Test-Pattern -Text $Text -Pattern $reviewRequestPattern) {
    $flow = "review-request"
    $reason = "Request asks for an engineering review."
  } elseif (Test-Pattern -Text $Text -Pattern $incidentPattern) {
    $flow = "incident"
    $reason = "Request describes production impact, outage, or urgent failure."
  } elseif (Test-Pattern -Text $Text -Pattern $releasePattern) {
    $flow = "release"
    $reason = "Request describes release, deployment, publishing, versioning, or rollback."
  } elseif (Test-Pattern -Text $Text -Pattern $bugfixPattern) {
    $flow = "bugfix"
    $reason = "Request describes a bug, failure, error, or regression."
  } elseif (Test-Pattern -Text $Text -Pattern $refactorPattern) {
    $flow = "refactor"
    $reason = "Request describes restructuring, cleanup, or simplification."
  } elseif (Test-Pattern -Text $Text -Pattern $knowledgePattern) {
    $flow = "knowledge-capture"
    $reason = "Request primarily asks to capture or update knowledge."
  }

  $stages = New-Object System.Collections.Generic.List[string]
  $skills = New-Object System.Collections.Generic.List[string]

  Add-Unique -List $skills -Values @("discover-context", "route-request")

  switch ($flow) {
    "review-feedback" {
      Add-Unique -List $stages -Values @("context", "triage-feedback", "plan", "implement", "verify", "review", "deliver", "memory")
      Add-Unique -List $skills -Values @("handle-review-feedback", "plan-work", "execute-plan", "implement-safely", "verify-before-delivery", "review-changes", "capture-memory")
    }
    "review-request" {
      Add-Unique -List $stages -Values @("context", "verify", "review", "deliver")
      Add-Unique -List $skills -Values @("verify-before-delivery", "request-review", "review-changes")
    }
    "incident" {
      Add-Unique -List $stages -Values @("context", "stabilize", "diagnose", "prove", "mitigate", "verify", "review", "deliver", "memory")
      Add-Unique -List $skills -Values @("diagnose-failure", "prove-behavior-first", "plan-work", "execute-plan", "implement-safely", "verify-before-delivery", "review-changes", "capture-memory")
    }
    "bugfix" {
      Add-Unique -List $stages -Values @("context", "reproduce", "diagnose", "prove", "design", "plan", "implement", "verify", "review", "deliver", "memory")
      Add-Unique -List $skills -Values @("diagnose-failure", "prove-behavior-first", "shape-design", "plan-work", "write-implementation-plan", "execute-plan", "implement-safely", "verify-before-delivery", "review-changes", "capture-memory")
    }
    "refactor" {
      Add-Unique -List $stages -Values @("context", "design", "plan", "implement", "verify", "review", "deliver", "memory")
      Add-Unique -List $skills -Values @("shape-design", "plan-work", "write-implementation-plan", "execute-plan", "implement-safely", "verify-before-delivery", "review-changes", "capture-memory")
    }
    "release" {
      Add-Unique -List $stages -Values @("context", "plan", "verify", "review", "release-readiness", "deliver", "memory")
      Add-Unique -List $skills -Values @("plan-work", "verify-before-delivery", "review-changes", "request-review", "release-readiness", "capture-memory")
    }
    "knowledge-capture" {
      Add-Unique -List $stages -Values @("context", "classify", "capture", "verify", "deliver")
      Add-Unique -List $skills -Values @("capture-memory", "verify-before-delivery", "review-changes")
    }
    default {
      Add-Unique -List $stages -Values @("context", "brainstorm", "design", "plan", "prove", "implement", "verify", "review", "deliver", "memory")
      Add-Unique -List $skills -Values @("shape-design", "plan-work", "write-implementation-plan", "prove-behavior-first", "execute-plan", "implement-safely", "verify-before-delivery", "review-changes", "capture-memory")
    }
  }

  if (Test-Pattern -Text $Text -Pattern $mcpPattern) {
    Add-Unique -List $skills -Values @("mcp-governance", "shape-design")
  }

  $id = New-RouteId -Text $Text
  $artifacts = @(
    "work/request-routing/latest.md",
    "work/request-routing/latest.json",
    "work/brainstorms/$id.md",
    "work/designs/$id.md",
    "work/plans/$id.md",
    "work/active/$id.md"
  )

  $safeGoal = $Text.Replace('"', "'")
  $harnessScript = Get-HarnessScriptCommandPath -HarnessRoot $HarnessRoot
  $nextCommand = "powershell -NoProfile -ExecutionPolicy Bypass -File $harnessScript brainstorm -Id `"$id`" -Topic `"Request routing: $flow`" -Goal `"$safeGoal`""

  return [ordered]@{
    id = $id
    prompt = $Text
    flow = $flow
    reason = $reason
    stages = @($stages)
    skills = @($skills)
    artifacts = $artifacts
    nextCommand = $nextCommand
    generatedAt = (Get-Date).ToUniversalTime().ToString("o")
  }
}

function Write-RouteArtifacts {
  param(
    [string]$HarnessRoot,
    [object]$Route
  )

  $directory = Join-Path $HarnessRoot "work/request-routing"
  if (-not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
  }

  $jsonPath = Join-Path $directory "latest.json"
  $markdownPath = Join-Path $directory "latest.md"

  $Route | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

  $lines = @(
    "# Request Routing",
    "",
    "- Generated: $($Route.generatedAt)",
    "- ID: $($Route.id)",
    "- Flow: $($Route.flow)",
    "- Reason: $($Route.reason)",
    "",
    "## Stages",
    ""
  )
  foreach ($stage in $Route.stages) {
    $lines += "- $stage"
  }
  $lines += @("", "## Skills", "")
  foreach ($skill in $Route.skills) {
    $lines += "- $skill"
  }
  $lines += @("", "## Artifacts", "")
  foreach ($artifact in $Route.artifacts) {
    $lines += "- $artifact"
  }
  $lines += @(
    "",
    "## Next Command",
    "",
    '```powershell',
    $Route.nextCommand,
    '```'
  )

  Set-Content -LiteralPath $markdownPath -Encoding UTF8 -Value ($lines -join [Environment]::NewLine)
}

$rootPath = Resolve-HarnessRoot -Path (Resolve-RequestedRoot -Path $Root)
$promptText = Get-PromptText -ExplicitPrompt $Prompt
$route = Get-Route -Text $promptText -HarnessRoot $rootPath

if (-not $NoWrite) {
  Write-RouteArtifacts -HarnessRoot $rootPath -Route $route
}

if ($Json) {
  $route | ConvertTo-Json -Depth 10 -Compress
} else {
  Write-Output "Harness Request Router"
  Write-Output "- flow: $($route.flow)"
  Write-Output "- stages: $($route.stages -join ' -> ')"
  Write-Output "- skills: $($route.skills -join ', ')"
  Write-Output "- next: $($route.nextCommand)"
}
