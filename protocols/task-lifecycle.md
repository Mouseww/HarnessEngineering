# Task Lifecycle Protocol

## Status

| Status | Meaning |
| --- | --- |
| proposed | User proposed it, but scope is not confirmed |
| active | Confirmed and in progress |
| blocked | Waiting for user input or an external system |
| verifying | Implementation is complete and under verification |
| reviewed | Review is complete |
| delivered | Delivered |
| archived | Archived |

## Task File

Active tasks are written to `work/active/<task-id>.md`.

Must include:

- Goal.
- Non-goals.
- File scope.
- Steps.
- Verification command.
- Risks.
- Current status.

## Status Transitions

- `proposed -> active`: user confirms scope.
- `active -> verifying`: implementation is complete.
- `verifying -> reviewed`: verification evidence exists.
- `reviewed -> delivered`: delivery notes are complete.
- `delivered -> archived`: knowledge capture is complete.
