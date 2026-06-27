---
name: project-auto-detect
description: "Trigger: project detection, new project, language detection, framework detection, stack discovery. Detects the active project's language, framework, tools, and test runner. Loads relevant skills and project-level AGENTS.md. Use at session start or when entering a new directory."
license: Apache-2.0
metadata:
  author: reeinharrrd
  version: "1.1"
---

## Activation Contract

Use this skill when:
- Session starts and need to detect the active project
- User says "nuevo proyecto", "qué proyecto es este", "detecta el stack"
- Entering a directory that may be a project root
- User asks "what language/framework is this?"

Do NOT use for:
- System context (use system-context skill instead)
- One-off file reads

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
  "skills": ["python-pro", "fastapi-expert", "sql-pro"],
  "has_agents": false,
  "has_docker": true,
  "has_ci": true
}
```

## Resolution Steps

### 1. Run Detection
```bash
./scripts/detect.sh
```

### 2. Read Project AGENTS.md (if exists)
```bash
cat AGENTS.md 2>/dev/null || cat CLAUDE.md 2>/dev/null || echo "no-project-rules"
```

### 3. Load Project Skills (if `.opencode/skills/` exists)
```bash
ls .opencode/skills/ 2>/dev/null || echo "no-project-skills"
```

### 4. Match skills from catalog based on detection

| Detection | Skills to load |
|-----------|---------------|
| rust + cargo | rust-engineer, cargo |
| go + go.mod | golang-pro, go-testing |
| python + fastapi | fastapi-expert, python-pro, sql-pro |
| python + django | django-expert, python-pro |
| node + nextjs | nextjs-developer, typescript-pro, react-expert |
| node + vue | vue-expert, typescript-pro |
| node + nest | nestjs-expert, typescript-pro |
| docker | devops-engineer |
| k8s | kubernetes-specialist, devops-engineer |
| terraform | terraform-engineer |

### 5. Report to user
- `[Proyecto: <name>] [Stack: <lang> + <frameworks>] [Skills: <n> loaded]`

## Output Contract

Returns:
- `detect.json` — full detection result
- Resolved skill paths for delegation
- Session context string for user output

## Anti-Patterns
- ❌ NO re-detect if already detected this session (cache result)
- ❌ NO load every skill — only relevant ones
- ❌ NO modify project files during detection
