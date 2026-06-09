$ErrorActionPreference = "Stop"

$mcp = Get-Content -LiteralPath ".mcp.json" -Raw | ConvertFrom-Json
if (-not $mcp.mcpServers.harness) {
  throw ".mcp.json missing harness server."
}

if (-not (Test-Path -LiteralPath "mcp/harness-server/server.js")) {
  throw "Harness MCP server missing."
}

$output = node "mcp/harness-server/server.js" --self-test
if ($LASTEXITCODE -ne 0) {
  throw "Harness MCP self-test failed."
}

if (($output -join "`n") -notlike "*Harness MCP self-test passed*") {
  throw "Unexpected MCP self-test output."
}

Write-Output "validate-mcp: OK"
