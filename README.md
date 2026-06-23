# Harness Engineering

Harness Engineering gives an existing codebase a Claude Code/Codex-ready engineering runtime: request routing, project skills, hooks, MCP tools, verification gates, memory, wiki, and automated review.

## Install Into An Existing Project

Run this from the root of the project you want to upgrade:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Mouseww/HarnessEngineering/main/scripts/install-harness.ps1 | iex; Install-Harness -Target . -Repo Mouseww/HarnessEngineering -Ref main"
```

Then start Claude Code from that same project root:

```powershell
claude
```

Use a first prompt like this:

```text
Use this repository's Harness Engineering runtime. Route my request first, then follow the selected flow, skills, hooks, and verification gates.
```

## Uninstall From A Project

Run this from the root of the project you want to clean:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Mouseww/HarnessEngineering/main/scripts/uninstall-harness.ps1 | iex; Uninstall-Harness -Target ."
```

The uninstaller removes `.harness/`, Harness bridge hooks/skills/subagents, Harness MCP registration, and Harness blocks in `README.md`, `CLAUDE.md`, and `AGENTS.md`. Project-owned files and non-Harness `.claude` entries are preserved.

## Daily Use

1. Ask Claude Code for real work from the project root.
2. Harness automatically routes the request into a flow, stages, skills, artifacts, and next command.
3. Before delivery, Harness runs verification, updates memory/code map/review artifacts, and blocks risky operations unless confirmed.

The normal loop is:

```text
request -> route -> plan -> implement -> verify -> review -> deliver -> memory
```

## Check Installation

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".harness/scripts/doctor.ps1"
```

Expected result:

```text
doctor: OK
```

Check current task and memory counts:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".harness/scripts/harness.ps1" status
```

## Route A Request Manually

Claude Code does this through hooks, but you can also test routing directly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".harness/scripts/route-request.ps1" -Prompt "Fix login failure and add regression verification"
```

It returns the flow, stages, skills, artifacts, and next command.

## What The Installer Adds

The installer keeps the real Harness runtime under one directory:

- `.harness/` contains `harness.yaml`, `agents/`, `core/`, `flows/`, `mcp/`, `protocols/`, `scripts/`, `wiki/`, `memory/`, `work/`, and the canonical `.claude/` runtime.
- `CLAUDE.md`, `AGENTS.md`, `.mcp.json`, `.claude/settings.json`, `.claude/hooks/`, `.claude/skills/`, and `.claude/agents/` remain at the project root only as thin discovery bridges for Claude Code, Codex, and MCP.

Existing `README.md`, `CLAUDE.md`, `AGENTS.md`, `.mcp.json`, and `.claude/settings.json` are preserved by appending or merging Harness configuration. Existing project-owned `.claude` skills, subagents, and scripts are preserved; only recognizable Harness-managed legacy files are upgraded or cleaned.

## Useful Commands

| Need | Command |
| --- | --- |
| Full health check | `powershell -NoProfile -ExecutionPolicy Bypass -File ".harness/scripts/doctor.ps1"` |
| Current status | `powershell -NoProfile -ExecutionPolicy Bypass -File ".harness/scripts/harness.ps1" status` |
| Route a request | `powershell -NoProfile -ExecutionPolicy Bypass -File ".harness/scripts/route-request.ps1" -Prompt "..."` |
| Create task | `powershell -NoProfile -ExecutionPolicy Bypass -File ".harness/scripts/harness.ps1" new-task -Id "task-id" -Title "Task title" -Flow "feature-development" -Goal "Task goal" -Verify "powershell -NoProfile -ExecutionPolicy Bypass -File .harness/scripts/doctor.ps1"` |
| Capture memory | `powershell -NoProfile -ExecutionPolicy Bypass -File ".harness/scripts/harness.ps1" capture-memory -Layer project -Title "Decision title" -Fact "Reusable fact" -Source "Source" -Verified` |
| Auto-maintenance | `powershell -NoProfile -ExecutionPolicy Bypass -File ".claude/hooks/auto-maintenance.ps1"` |
| Uninstall Harness | `powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Mouseww/HarnessEngineering/main/scripts/uninstall-harness.ps1 \| iex; Uninstall-Harness -Target ."` |

## Use This Repository Directly

If you are developing Harness Engineering itself:

```powershell
git clone https://github.com/Mouseww/HarnessEngineering.git
cd HarnessEngineering
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/doctor.ps1"
```

## What Harness Does

- Routes every request into an engineering flow.
- Loads project skills for planning, design, implementation, debugging, review, and memory.
- Blocks dangerous git/delete/production operations unless confirmed.
- Provides MCP tools for task creation, memory capture, workflow artifacts, and request routing.
- Generates memory index, code map, workflow gates, and automated review reports.

## Key Directories

| Path | Responsibility |
| --- | --- |
| `.harness/` | Canonical Harness runtime, scripts, memory, wiki, MCP server, protocols, flows, and work state |
| `.claude/` | Thin Claude Code discovery bridges that load canonical files from `.harness/.claude/` |
| `.mcp.json` | Thin MCP bridge pointing to `.harness/mcp/harness-server/server.js` |
| `CLAUDE.md` | Thin Claude Code guide pointing to `.harness/harness.yaml` and canonical protocols |
| `AGENTS.md` | Thin Codex/agent guide pointing to `.harness/agents/registry.yaml` |
