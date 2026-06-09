# Memory Contract

## Goal

Extract reusable facts, decisions, conventions, and failure patterns from chat into durable memory.

## Layers

| Layer | Path | Content |
| --- | --- | --- |
| team | `memory/team/` | Long-lived team standards and cross-project knowledge |
| project | `memory/project/` | Current project facts, decisions, and verification records |
| agent | `memory/agents/<agent-id>/` | Runtime adaptation experience |

## Record Format

- Date.
- Source.
- Fact.
- Scope.
- Verification status.

## Prohibited

- Secrets, tokens, cookies, or personal private data.
- One-off chat sentiment.
- Guesses without sources.
