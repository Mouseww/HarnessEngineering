# Engineering Principles

## KISS

Prefer the simplest, lowest-state, easiest-to-verify solution.

## YAGNI

Implement only what is explicitly needed now. Do not reserve complex structures for unconfirmed future needs.

## DRY

Repeated rules, flows, and checklists must be moved into shared protocols or scripts.

## SOLID

- Single responsibility: each protocol, flow, hook, and skill owns one boundary.
- Open/closed: add agents through registry and manifest entries.
- Liskov substitution: agent adapters must not break core protocol expectations.
- Interface segregation: MCP tools and hooks keep small interfaces.
- Dependency inversion: agents depend on tool-agnostic protocols, not on each other.
