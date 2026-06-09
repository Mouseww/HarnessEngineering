# Risk Confirmation Protocol

## Operations Requiring Confirmation

- Delete files or directories.
- Batch modify or move many files.
- `git commit`, `git push`, `git reset --hard`, or forced branch switching.
- Modify system environment variables, permissions, or global configuration.
- Database deletion, schema changes, or batch updates.
- Call production APIs or send sensitive data.
- Globally install, uninstall, or upgrade core dependencies.

## Confirmation Format

```text
High-risk operation detected
Operation type: <specific operation>
Impact scope: <detailed scope>
Risk assessment: <potential consequences>

Please confirm whether to continue. Requires an explicit "yes", "confirm", or "continue".
```

## When Not Confirmed

The agent may only perform read-only diagnosis, planning, or local reversible preparation. It must not execute the risky operation.
