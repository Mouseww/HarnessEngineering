# Harness Engineering Design

## Goal

Build a production-usable team engineering skeleton covering general software engineering, AI agent engineering, and enterprise delivery governance.

## Current Stage

- Multi-agent compatibility.
- First-class Claude Code support.
- Codex adapter support.
- Final target is tool-agnostic protocols.

## Architecture

Core protocols live in `protocols/`. Claude Code runtime configuration lives in `.claude/`. Agent routing lives in `agents/registry.yaml`. MCP capabilities live in `mcp/`. Long-lived knowledge is split between `wiki/` and `memory/`.

## Non-Goals

- Do not create demo projects.
- Do not create sample MCP.
- Do not bind to a single agent.
- Do not execute git commit or push.

## Verification

This design validates structure through `scripts/doctor.ps1`, `scripts/validate-claude-code.ps1`, `scripts/validate-mcp.ps1`, and `scripts/validate-hooks.ps1`.
