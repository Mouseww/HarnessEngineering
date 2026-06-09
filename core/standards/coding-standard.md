# Coding Standard

- Keep file responsibilities clear.
- Do not introduce unverified dependencies.
- Do not mix configuration, protocols, and implementation in the same file.
- Comments follow the repository language; this repository defaults to English.
- PowerShell scripts must set `$ErrorActionPreference = "Stop"`.
- JSON files must parse with `ConvertFrom-Json`.
