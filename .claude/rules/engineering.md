# Engineering Rules

- Read before writing: read relevant files, configuration, and protocols before modifying them.
- KISS: choose the most direct implementation with the least state and abstraction.
- YAGNI: implement only capabilities explicitly required by the current task.
- DRY: move repeated rules into `protocols/`, `core/`, or shared scripts.
- SOLID: prefer single responsibility; agent adapters must not pollute tool-agnostic protocols.
- Verification first: run commands that prove the current change before delivery.
- Language consistency: repository documentation, skills, runtime guides, generated artifacts, and comments default to English.
