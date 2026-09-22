---
name: project-auto-detect
classification: CORE
description: "Trigger: project detection, new project, language detection, framework detection, stack discovery. Detects cwd → repository → project root → stack → project context → returns metadata ONLY. Does not select models, load skills, or decide memory. Use at session start or when entering a new directory."
license: Apache-2.0
metadata:
  author: reeinhardrrd
  version: "2.0"
---

## Activation Contract

Use this skill when:
- Session starts and need to detect the active project
- User says "nuevo proyecto", "qué proyecto es este", "detecta el stack"
- Entering a directory that may be a project root
- User asks "what language/framework is this?"

Do NOT use for:
- System context → `system-context` (on-demand)
- Loading skills → `skill-router` (on-demand)
- Selecting models/agents → OMO (routing authority)
- Memory decisions → Engram policy (`instructions/00-memory-policy.md`)

## Exclusive responsibility

```
cwd → repository? → project root → stack → project context → return metadata
```

Nothing else. Detection is read-only and side-effect free regarding routing, skills, and memory.

## Detection Script

Run `scripts/detect.sh` from the project root to get structured JSON:

```json
{
  "project_name": "my-app",
  "language": "python",
  "frameworks": ["fastapi"],
  "test_runner": "pytest",
  "package_manager": "uv",
  "build_tool": null,
  "skill_hints": ["python-pro", "fastapi-expert"],
  "has_agents": false,
  "has_docker": true,
  "has_ci": true
}
```

`skill_hints` are **names only** for later skill-router lookup — do not invoke them here.

## Resolution Steps

### 1. Detect root
- If cwd has no repo marker (`package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `.git`, …) up to git root → return `{"project": false}`. Outside a project: stop; global contract only.

### 2. Run Detection
```bash
./scripts/detect.sh
```

### 3. Read Project rules if present
```bash
# AGENTS.md first, else CLAUDE.md — read, do not expand
```

### 4. Check PCC artifacts (report presence only)
- `PROJECT_CONTEXT.md`, `.opencode/STATE.md`, `.codegraph/`
- Missing → note as suggestion (Core Generator / user may provision). Never overwrite silently.

### 5. Report metadata
- `[Proyecto: <name>] [Stack: <lang> + <frameworks>]` + artifact presence.
- Do NOT load skills, do NOT pick models, do NOT write STATE.

## Output Contract

Returns:
- `detect.json` — full detection result
- PCC artifact presence flags
- Session context string (one line)

Skill activation, model routing, and memory remain owned by skill-router, OMO, and Engram respectively.

## Anti-Patterns
- ❌ Re-detect if already detected this session (cache result)
- ❌ Load skills during detection (hand off to skill-router)
- ❌ Select models/agents during detection (OMO owns routing)
- ❌ Modify project files during detection
- ❌ Treat "no project" as an error — outside a project is a valid, minimal state
