---
name: skill-router
classification: CORE
description: >
  Sole authority for loading skills outside the always-on CORE tier. Classifies CORE /
  WORKFLOW / DOMAIN, resolves project skills, falls back to capability-scanner.
  Trigger: "I need a skill for X", "which skill does Y", "load <name>", "find tool for Z".
---

# Skill Router — sole loading authority

> **Única autoridad para decidir qué skill se carga** (fuera del tier CORE inyectado).
> No enumera bodega; inventario = `capabilities/skills.md` + manifests `plugins/bodega-*.json`.

## Classification (owned here)

| Class | Meaning | Load |
|-------|---------|------|
| **CORE** | Lifecycle / routing / harness behavior | Always available in session; invoke by name when trigger matches. `system-context` is CORE-tier but **on-demand activation**. |
| **WORKFLOW** | Development process skills | Load when task matches description (lazy). |
| **DOMAIN** | Utility / content skills | Load only on explicit need (lazy). |
| **BODEGA** | ~1280 external, in manifests | Discover via scanner / manifests; never preload. |

Inventory table: `capabilities/skills.md` (documentation). Structural manifests: `harness-registry.jsonc` (OLA 12) + `plugins/bodega-*.json` (generated).

## Flow

### 1. CORE tier match?

| Task | CORE skill |
|------|------------|
| Session principles / behavior | `core-constitution` |
| Project/stack detection | `project-auto-detect` |
| Current work state | `state-tracking` |
| Session handoff | `handoff` |
| DCP extract / protect | `auto-extract`, `auto-protect-wrap` |
| Pre-compaction checkpoint | `pre-compaction-save` |
| Machine context (explicit ask only) | `system-context` |
| Unregistered capability discovery | `capability-scanner` |
| Routing itself | `skill-router` (you are here) |

→ Invoke the target directly; do not re-route through this skill.

### 2. Project skill?

→ Read `<project-root>/PROJECT_CONTEXT.md` § Project Skills (root, not `.opencode/`).
→ If listed → `skill(name="<skill>")`.

### 3. WORKFLOW / DOMAIN in inventory?

→ Check `capabilities/skills.md` classification tables (lazy read).
→ Match → `skill(name="<skill>")`.

### 4. Nothing in CORE / project / inventory?

→ Run `capability-scanner`:
```bash
~/.config/opencode/scripts/capability-scanner.sh "$PWD"
```
→ If discovered → `skill(name="...")` or enable project MCP.
→ Also consult `plugins/bodega-ondemand-skills.json` (names only).

### 5. Still no match?

→ Ask reeinharrrd, or propose creating a skill (`skill-creator` in bodega), or `npm search`.

## Golden rule

**Never invoke a skill that does not exist.** Invalid `skill(name=...)` errors.
Verify against: CORE list → project → inventory → scanner output.

## Anti-patterns

- ❌ Preload WORKFLOW/DOMAIN “just in case”
- ❌ Claim “no skill for X” without `capability-scanner`
- ❌ Duplicate authority: another doc telling you to load skills bypassing this router
- ❌ Treat `system-context` as auto-load on session start (explicit triggers only)
- ❌ Point at dead paths (`REGISTRY.md`, `domain-registry/`) — use inventory + scanner

## Output contract

When invoked, reply with:
1. Class: CORE | WORKFLOW | DOMAIN | BODEGA | PROJECT
2. Exact name
3. `skill(name="<name>")` (or “no match → scanner / ask user”)
