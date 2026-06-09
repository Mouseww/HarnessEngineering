# Harness Engineering

Harness Engineering is a team-level engineering operating skeleton that unifies general software engineering, AI agent engineering, and enterprise delivery governance under one protocol system.

Current stage goals:

- Support multi-agent collaboration.
- Treat Claude Code as a first-class runtime.
- Keep adapter entry points for Codex, Cursor, Gemini CLI, and similar tools.
- Store core rules first as tool-agnostic protocols, then let each agent runtime load them.

## Quick Start

### One-Line Install Into Existing Projects

Run this from an existing project root to install the Harness runtime into that project:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Mouseww/HarnessEngineering/main/scripts/install-harness.ps1 | iex; Install-Harness -Target . -Repo Mouseww/HarnessEngineering -Ref main"
```

The installer preserves existing `README.md`, `CLAUDE.md`, `AGENTS.md`, `.mcp.json`, and `.claude/settings.json` by appending or merging Harness configuration. Other same-path file conflicts stop the install unless `-Force` is explicitly supplied.

1. Run the full check from the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/doctor.ps1"
```

2. Inspect the current Harness status:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/harness.ps1" status
```

3. Create a real task file:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/harness.ps1" new-task -Id "task-id" -Title "Task title" -Flow "feature-development" -Goal "Task goal" -Verify "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/doctor.ps1"
```

4. Capture one project memory:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/harness.ps1" capture-memory -Layer project -Title "Decision title" -Fact "Reusable fact" -Source "Source" -Verified
```

5. Claude Code users start from the repository root so Claude Code can load:

- `CLAUDE.md`
- `.claude/settings.json`
- `.claude/skills/`
- `.claude/agents/`
- `.mcp.json`

6. Codex users start from the repository root so Codex can load:

- `AGENTS.md`
- `harness.yaml`
- `agents/registry.yaml`

## Operating Principles

- Core rules live in `protocols/` and `core/` to avoid binding them to one agent.
- Agent-specific entry points only handle load paths, runtime limits, and tool adaptation.
- Every task must include context discovery, planning, implementation, verification, review, delivery, and memory capture.
- Chat history must not replace task state; long-lived state goes into `work/`, `wiki/`, or `memory/`.

## Key Directories

| Path | Responsibility |
| --- | --- |
| `.claude/` | First-class Claude Code runtime configuration, skills, subagents, and hooks |
| `agents/` | Multi-agent routing registry and adapter manifests |
| `protocols/` | Tool-agnostic engineering protocols |
| `core/` | Engineering standards, principles, and checklists |
| `flows/` | Team task flows |
| `hooks/` | Hook scripts and shared policies |
| `mcp/` | MCP services, catalog, contracts, and policies |
| `wiki/` | Team knowledge base |
| `memory/` | Layered team, project, and agent memory |
| `work/` | Active, completed, and archived task state |
| `scripts/` | Local validation and diagnostic scripts |

## Executable Capabilities

| Capability | Command or Entry | Effect |
| --- | --- | --- |
| Status query | `scripts/harness.ps1 status` | Outputs active task and memory counts |
| Task creation | `scripts/harness.ps1 new-task` | Writes `work/active/<id>.md` |
| Memory capture | `scripts/harness.ps1 capture-memory` | Writes `memory/<layer>/` and updates `memory/index.yaml` |
| Brainstorm | `scripts/harness.ps1 brainstorm` | Writes `work/brainstorms/<id>.md` |
| Design artifact | `scripts/harness.ps1 design` | Writes `work/designs/<id>.md` |
| Plan artifact | `scripts/harness.ps1 plan` | Writes `work/plans/<id>.md` |
| Implementation checkpoint | `scripts/harness.ps1 checkpoint` | Updates `work/active/<id>.md` and `work/implementation-log.md` |
| Workflow status | `scripts/harness.ps1 workflow-status` | Queries brainstorm/design/plan/task/checkpoint status |
| Hook guard | `.claude/hooks/pre-tool-guard.ps1` | Blocks unauthorized git push/commit/reset operations |
| Prompt guidance | `.claude/hooks/workflow-guidance.ps1` | Outputs workflow guidance during Claude Code `UserPromptSubmit` |
| Request routing | `scripts/route-request.ps1` | Maps user requests to flow, stage, skill, artifacts, and next command |
| Auto-maintenance hook | `.claude/hooks/auto-maintenance.ps1` | Updates memory, code map, and review on Claude Code `Stop` |
| Memory improvement | `scripts/update-memory-index.ps1` | Generates `memory/auto-index.md` and `memory/health.md` |
| Code structure map | `scripts/generate-code-map.ps1` | Generates `wiki/architecture/code-map.md` |
| Automated review | `scripts/review-changes.ps1` | Generates `work/reviews/latest-review.md` |
| MCP status | `harness_status` | Returns Harness structure status |
| MCP read | `harness_read` | Reads registered Harness files |
| MCP task creation | `harness_create_task` | Writes local task files through MCP |
| MCP memory capture | `harness_capture_memory` | Writes local memory through MCP |
| MCP workflow | `harness_create_brainstorm/design/plan` | Writes workflow artifacts through MCP |
| MCP checkpoint | `harness_update_task_checkpoint` | Records implementation evidence through MCP |
| MCP request routing | `harness_route_request` | Automatically plans the flow for the current request through MCP |

## Automated Hook Artifacts

Claude Code's `Stop` hook runs:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".claude/hooks/auto-maintenance.ps1"
```

It updates:

- `work/request-routing/latest.md`
- `work/request-routing/latest.json`
- `memory/auto-index.md`
- `memory/health.md`
- `wiki/architecture/code-map.md`
- `work/reviews/latest-review.md`
- `work/workflow-gates.md`

These artifacts are deterministic engineering signals generated by scripts. They do not replace human judgment or deeper model review.
