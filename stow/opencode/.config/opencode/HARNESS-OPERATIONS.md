# OpenCode Global Harness Operations

## Sources of truth

- Runtime: `opencode.jsonc`
- Agent routing: `~/.omo/omo.jsonc`
- Capability registry: `harness-registry.jsonc`
- Skills, agents, and commands: generated bodega manifests
- Durable decisions: Engram project `opencode`
- Code intelligence: CodeGraph and Codebase Memory

Backups and legacy files are recovery material. They must not be edited as active configuration.

## Execution profiles

- `research`: read-only, web/docs/MCP access, no project writes.
- `standard`: project edits, tests, formatter, and LSP.
- `builder`: standard plus installs and controlled background tasks.
- `release`: git/CI/deployment actions require explicit approval.
- `security`: read-only analysis and security tools by default.

## Completion contract

Every non-trivial task must leave: changed files, verification commands, unresolved risks, and an
Engram observation when a decision, bugfix, configuration change, or reusable pattern was found.

## Retention

Do not delete sessions, Engram data, backups, or repositories automatically. CodeGraph exceeds the
review threshold when its project store is larger than 2 GiB; prune only after inspecting old
project entries and preserving the active projects.
