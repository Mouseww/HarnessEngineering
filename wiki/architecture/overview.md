# Architecture Overview

Harness Engineering is protocol-first:

- `protocols/` defines tool-agnostic contracts.
- `.claude/` provides the first-class Claude Code runtime.
- `agents/` provides multi-agent routing.
- `mcp/` provides governed tool capabilities.
- `memory/` and `wiki/` provide long-lived knowledge.
