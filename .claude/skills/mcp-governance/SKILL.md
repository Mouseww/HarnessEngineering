---
name: mcp-governance
description: Use when adding, changing, reviewing, or using MCP servers, tools, resources, or permissions.
---

# MCP Governance

## Core Principle

MCP is a governed capability boundary, not an unlimited toolbox. Every tool must have clear permissions, inputs, outputs, and verification.

## Hard Gate

Before MCP work:

1. Read `protocols/mcp-contract.md`.
2. Check whether `mcp/catalog.yaml` already has the capability.
3. Confirm tool input/output and permission level.
4. High-risk write operations require user confirmation.
5. New MCP capabilities must be checkable by `scripts/validate-mcp.ps1`.

## Quick Reference

| Level | Meaning |
| --- | --- |
| read | Read-only resource |
| local-write | Local reversible write |
| external-write | External system write |
| destructive | Deletion, overwrite, or production change |

## Red Flags

- Tool permission is higher than the task requires.
- Inputs or outputs have no schema or example.
- External write has no user confirmation.
- Catalog and server implementation disagree.
- New capability is not covered by validation scripts.

## Verification

- `mcp/catalog.yaml` matches implementation.
- `scripts/validate-mcp.ps1` passes.
- High-risk tools have confirmation paths and failure handling.
