---
name: auto-extract
version: "1.0.0"
description: "Auto-distills large tool outputs using DCP extract tool"
author: reeinharrrd
license: MIT
compatibility: ">= 3.0.0"
---

# Auto-Extract Skill

Automatically distills large tool outputs (>3000 chars) using DCP's extract tool, preserving key findings while reducing token usage.

## Trigger

- Tool outputs >3000 characters
- DCP extract tool available

## Behavior

1. Detects large output
2. If extract tool available: marks for agent to run extract
3. Fallback: truncates with summary marker

## Usage

```bash
# Manual test
echo "large output..." | auto-extract task
```

## Integration

```json
{
  "hooks": {
    "auto_extract": {
      "enabled": true,
      "command": "auto-extract"
    }
  }
}
```