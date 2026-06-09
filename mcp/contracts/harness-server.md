# Harness MCP Server Contract

## Goal

`mcp/harness-server/server.js` provides repository engineering protocol reads and local Harness action capabilities.

## Tools

| Tool | Permission | Description |
| --- | --- | --- |
| `harness_status` | read | Return key directory and configuration status |
| `harness_read` | read | Read Harness files in the allowed scope |
| `harness_create_task` | local-write | Create `work/active` task files |
| `harness_capture_memory` | local-write | Create memory records and update the index |
| `harness_create_brainstorm` | local-write | Create `work/brainstorms` brainstorm artifacts |
| `harness_create_design` | local-write | Create `work/designs` design artifacts |
| `harness_create_plan` | local-write | Create `work/plans` plan artifacts |
| `harness_update_task_checkpoint` | local-write | Update active tasks and the implementation log |
| `harness_workflow_status` | read | Query task workflow status |
| `harness_route_request` | local-write | Route user requests and write `work/request-routing/latest.*` |

## Resources

- `harness://harness.yaml`
- `harness://agents/registry.yaml`
- `harness://protocols`

## Safety Boundaries

- Default to read-only; `harness_create_task` and `harness_capture_memory` may only write inside the local repository.
- Workflow write tools may only write to `work/brainstorms`, `work/designs`, `work/plans`, `work/active`, and `work/implementation-log.md`.
- The request router may only write `work/request-routing/latest.json` and `work/request-routing/latest.md`.
- Do not read `.git/`.
- Do not read `.claude/agent-memory/`.
- Do not read paths outside the repository.
