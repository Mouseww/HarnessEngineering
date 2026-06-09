# MCP Contract

## Goal

Define registration, permission, input/output, and verification rules for MCP capabilities.

## MCP Capability Types

| Type | Description |
| --- | --- |
| resource | Read-only context resource |
| tool | Executable operation |
| prompt | Reusable prompt template |

## Permission Levels

| Level | Description |
| --- | --- |
| read | Read-only |
| local-write | Local reversible write |
| external-write | External system write |
| destructive | Deletion, overwrite, or production change |

## Registration Requirements

Every MCP capability must be registered in `mcp/catalog.yaml` with:

- Name.
- Type.
- Permission level.
- Inputs.
- Outputs.
- Verification method.

## Prohibited

- MCP capabilities without catalog registration.
- MCP tools without permission levels.
- Unconfirmed destructive operations.
