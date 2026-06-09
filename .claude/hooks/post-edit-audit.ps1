$ErrorActionPreference = "Stop"

$root = (Get-Location).Path
$auditDir = Join-Path $root ".claude/agent-memory"
$auditPath = Join-Path $auditDir "tool-audit.jsonl"

New-Item -ItemType Directory -Force -Path $auditDir | Out-Null

$stdin = [Console]::In.ReadToEnd()
$record = [ordered]@{
  timestamp = (Get-Date).ToUniversalTime().ToString("o")
  event = "post-edit"
  payload = $stdin
}

($record | ConvertTo-Json -Compress -Depth 20) | Add-Content -LiteralPath $auditPath -Encoding UTF8

$workDir = Join-Path $root "work"
$logPath = Join-Path $workDir "implementation-log.md"
New-Item -ItemType Directory -Force -Path $workDir | Out-Null
if (-not (Test-Path -LiteralPath $logPath)) {
  Set-Content -LiteralPath $logPath -Encoding UTF8 -Value "# Implementation Log"
}
Add-Content -LiteralPath $logPath -Encoding UTF8 -Value (@(
  "",
  "## $((Get-Date).ToUniversalTime().ToString("o"))",
  "",
  "- Source: .claude/hooks/post-edit-audit.ps1",
  "- Tool: $($record.payload | Select-Object -First 1)"
) -join [Environment]::NewLine)
exit 0
