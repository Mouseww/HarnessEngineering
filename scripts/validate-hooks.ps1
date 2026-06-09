$ErrorActionPreference = "Stop"

$hooks = Get-ChildItem -LiteralPath ".claude/hooks" -Filter "*.ps1"
foreach ($hook in $hooks) {
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($hook.FullName, [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors.Count -gt 0) {
    throw "PowerShell parse error in $($hook.FullName): $($errors[0].Message)"
  }
}

function Invoke-Guard {
  param(
    [Parameter(Mandatory = $true)][string]$Json
  )

  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "powershell"
  $psi.Arguments = '-NoProfile -ExecutionPolicy Bypass -File ".claude/hooks/pre-tool-guard.ps1"'
  $psi.RedirectStandardInput = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.UseShellExecute = $false
  $process = [System.Diagnostics.Process]::Start($psi)
  $process.StandardInput.Write($Json)
  $process.StandardInput.Close()
  $process.WaitForExit()
  return $process.ExitCode
}

$allowed = Invoke-Guard -Json '{"tool_name":"Bash","tool_input":{"command":"rg -n \"Harness\" \"README.md\""}}'
if ($allowed -ne 0) {
  throw "pre-tool guard blocked allowed read command."
}

$blocked = Invoke-Guard -Json '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}'
if ($blocked -ne 2) {
  throw "pre-tool guard did not block git push."
}

Write-Output "validate-hooks: OK"
