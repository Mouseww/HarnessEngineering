# Harness Engineering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a production-usable Harness Engineering team engineering skeleton.

**Architecture:** Root entry points load tool-agnostic protocols. Claude Code is first-class through `.claude/`; Codex and other agents adapt through the registry. MCP, hooks, wiki, and memory are constrained by independent contracts.

**Tech Stack:** Markdown, YAML, JSON, PowerShell, Node.js.

---

### Task 1: Runtime Entrypoints

**Files:**
- Create: `README.md`
- Create: `CLAUDE.md`
- Create: `AGENTS.md`
- Create: `harness.yaml`
- Create: `agents/registry.yaml`

- [x] Create root entry points and agent routing.
- [x] Confirm Claude Code and Codex are separated.

### Task 2: Claude Code Runtime

**Files:**
- Create: `.claude/settings.json`
- Create: `.claude/skills/*/SKILL.md`
- Create: `.claude/agents/*.md`
- Create: `.claude/hooks/*.ps1`

- [x] Create settings, skills, subagents, and hooks.
- [x] Create skill pressure scenario records.

### Task 3: Protocols And Knowledge

**Files:**
- Create: `protocols/*.md`
- Create: `flows/*.md`
- Create: `core/**/*.md`
- Create: `wiki/**/*.md`
- Create: `memory/**/*.md`

- [x] Create tool-agnostic protocols.
- [x] Create flows, wiki, memory, and checklists.

### Task 4: MCP And Validation

**Files:**
- Create: `mcp/harness-server/server.js`
- Create: `mcp/catalog.yaml`
- Create: `scripts/*.ps1`

- [x] Create the local Harness MCP Server.
- [x] Create structure and behavior validation scripts.
- [x] Run verification commands.

### Task 5: Action Layer

**Files:**
- Create: `scripts/harness.ps1`
- Create: `scripts/validate-actions.ps1`
- Modify: `mcp/harness-server/server.js`
- Modify: `scripts/doctor.ps1`

- [x] Create `status`, `new-task`, and `capture-memory` commands.
- [x] Extend MCP tools with `harness_create_task` and `harness_capture_memory`.
- [x] Validate task creation, memory capture, and MCP action self-test in a temporary directory.

### Task 6: Automatic Maintenance Hooks

**Files:**
- Create: `.claude/hooks/auto-maintenance.ps1`
- Create: `scripts/update-memory-index.ps1`
- Create: `scripts/generate-code-map.ps1`
- Create: `scripts/review-changes.ps1`
- Create: `scripts/validate-automation-hooks.ps1`
- Modify: `.claude/settings.json`
- Modify: `scripts/doctor.ps1`

- [x] Add a Claude Code `Stop` hook to trigger auto-maintenance.
- [x] Automatically generate memory auto-index and health report.
- [x] Automatically generate the code structure map.
- [x] Automatically generate the deterministic review report.
- [x] Add automation hook validation to doctor.

### Task 7: Workflow Capability Layer

**Files:**
- Create: `scripts/validate-workflow-capabilities.ps1`
- Create: `.claude/hooks/workflow-guidance.ps1`
- Create: `scripts/update-workflow-gates.ps1`
- Modify: `scripts/harness.ps1`
- Modify: `mcp/harness-server/server.js`
- Modify: `.claude/settings.json`
- Modify: `scripts/doctor.ps1`

- [x] Add brainstorm/design/plan/checkpoint/workflow-status CLI commands.
- [x] Add the UserPromptSubmit workflow guidance hook.
- [x] Add the workflow gate report.
- [x] Add MCP workflow tools.
- [x] Validate workflow artifacts, checkpoints, guidance, gates, and MCP self-test in a temporary directory.

### Task 8: Request Flow Router

**Files:**
- Create: `scripts/route-request.ps1`
- Create: `scripts/validate-flow-router.ps1`
- Create: `work/request-routing/.gitkeep`
- Modify: `.claude/hooks/workflow-guidance.ps1`
- Modify: `mcp/harness-server/server.js`
- Modify: `mcp/catalog.yaml`
- Modify: `scripts/doctor.ps1`

- [x] Add the deterministic request router.
- [x] Change the UserPromptSubmit hook to call the request router.
- [x] Generate `work/request-routing/latest.md` and `latest.json`.
- [x] Add the `harness_route_request` MCP tool.
- [x] Add flow router validation to doctor.
