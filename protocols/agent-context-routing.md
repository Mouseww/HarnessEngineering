# Agent Context Routing Protocol

## Goal

Allow any agent to locate its own entry point, shared protocols, memory, wiki, hooks, MCP, and runtime rules from one registry.

## Routing Order

1. Read `harness.yaml`.
2. Read `agents/registry.yaml`.
3. Identify the current agent ID.
4. Match `agents.<agent-id>`.
5. Load that agent's `runtime_entry`, `manifest`, and `shared`.
6. If the agent ID is not found, fall back to `default_agent`.
7. If fallback fails, load only `protocols/context-loading.md` and `protocols/risk-confirmation.md`.

## Prohibited

- Agent-specific directories must not redefine core protocols.
- Agent adapters must not modify other agents' runtime entries.
- Chat context must not replace the registry.

## Minimum Success Standard

- The current agent entry can be located.
- Shared protocols can be located.
- Team memory and project memory can be located.
- Current runtime limits can be explained.
