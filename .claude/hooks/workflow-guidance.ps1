param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

$stdin = [Console]::In.ReadToEnd()
$text = $stdin
try {
  if (-not [string]::IsNullOrWhiteSpace($stdin)) {
    $payload = $stdin | ConvertFrom-Json
    if ($payload.prompt) {
      $text = [string]$payload.prompt
    }
  }
} catch {
  $text = $stdin
}

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "../..")).Path
$router = Join-Path $repoRoot "scripts/route-request.ps1"
$routeJson = powershell -NoProfile -ExecutionPolicy Bypass -File $router -Root $Root -Prompt $text -Json
$route = $routeJson | ConvertFrom-Json

Write-Output "Harness Request Router"
Write-Output "- flow: $($route.flow)"
Write-Output "- stages: $($route.stages -join ' -> ')"
Write-Output "- skills: $($route.skills -join ', ')"
Write-Output "- next: $($route.nextCommand)"
