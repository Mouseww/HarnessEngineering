$ErrorActionPreference = "Stop"

$stdin = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($stdin)) {
  exit 0
}

try {
  $payload = $stdin | ConvertFrom-Json
} catch {
  exit 0
}

$toolName = [string]$payload.tool_name
$inputJson = ($payload.tool_input | ConvertTo-Json -Depth 20 -Compress)

$blockedPatterns = @(
  "git\s+reset\s+--hard",
  "git\s+push\b",
  "git\s+commit\b",
  "git\s+checkout\s+--",
  "Remove-Item\s+.+-Recurse",
  "\brm\s+-rf\b"
)

foreach ($pattern in $blockedPatterns) {
  if ($inputJson -match $pattern) {
    [Console]::Error.WriteLine("Harness guard blocked high-risk operation. Request explicit user confirmation before running: $pattern")
    exit 2
  }
}

if (($toolName -eq "Write" -or $toolName -eq "Edit" -or $toolName -eq "MultiEdit") -and $inputJson -match "\\.git[\\/]")
{
  [Console]::Error.WriteLine("Harness guard blocked direct writes under .git.")
  exit 2
}

exit 0
