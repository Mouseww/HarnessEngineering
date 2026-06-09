# Context Loading Protocol

## Goal

Ensure agents have enough factual context before making changes.

## Required Reading Order

1. `harness.yaml`
2. `agents/registry.yaml`
3. Current agent manifest
4. Task-relevant `flows/`
5. Task-relevant `core/checklists/`
6. Current task in `work/active/`
7. Relevant code, configuration, wiki, and memory

## Output Requirements

Before implementation starts, the agent must be able to explain:

- Current goal.
- File scope.
- Main risks.
- Verification method.

## Failure Handling

If context is insufficient, state the specific gap first. Do not guess the implementation.
