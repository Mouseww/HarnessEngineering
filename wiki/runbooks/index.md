# Runbooks

## Runbooks

- Harness structure check: run `scripts/doctor.ps1`.
- Harness status query: run `scripts/harness.ps1 status`.
- Automatic request routing: run `scripts/route-request.ps1 -Prompt "..."`.
- Create task: run `scripts/harness.ps1 new-task`.
- Create brainstorm: run `scripts/harness.ps1 brainstorm`.
- Create design: run `scripts/harness.ps1 design`.
- Create plan: run `scripts/harness.ps1 plan`.
- Record checkpoint: run `scripts/harness.ps1 checkpoint`.
- View workflow status: run `scripts/harness.ps1 workflow-status`.
- Capture memory: run `scripts/harness.ps1 capture-memory`.
- Auto-maintenance: run `.claude/hooks/auto-maintenance.ps1`.
- Memory index: inspect `memory/auto-index.md` and `memory/health.md`.
- Code structure map: inspect `wiki/architecture/code-map.md`.
- Automated review: inspect `work/reviews/latest-review.md`.
- Workflow gate: inspect `work/workflow-gates.md`.
- Hook check: run `scripts/validate-hooks.ps1`.
- MCP check: run `scripts/validate-mcp.ps1`.
