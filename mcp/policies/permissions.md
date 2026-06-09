# MCP Permission Policy

## Default Policy

All MCP capabilities default to read-only. Before adding write capability, update:

- `protocols/mcp-contract.md`
- `mcp/catalog.yaml`
- Relevant validation scripts

## High-Risk Capabilities

`external-write` and `destructive` must request user confirmation before invocation.

## Current Server

The `harness` server reads protocols by default and allows local reversible writes:

- `harness_create_task`
- `harness_capture_memory`
- `harness_create_brainstorm`
- `harness_create_design`
- `harness_create_plan`
- `harness_update_task_checkpoint`
- `harness_route_request`

These tools may only write to `work/active`, `work/brainstorms`, `work/designs`, `work/plans`, `work/request-routing`, `work/implementation-log.md`, and `memory`.
