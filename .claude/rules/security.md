# Security Rules

- Deletion, batch modification, system configuration, permission changes, production APIs, destructive database operations, and global package management require user confirmation first.
- Do not write tokens, secrets, cookies, sessions, or private credentials into the repository.
- MCP servers expose only the minimum required tools and resources.
- Hook scripts must not silently execute destructive commands.
- External network requests must state purpose, scope, and data type.
