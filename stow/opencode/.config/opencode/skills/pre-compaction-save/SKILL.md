---
name: pre-compaction-save
version: "1.0.0"
description: "Auto-saves session summary to engram before context compaction"
author: reeinharrrd
license: MIT
compatibility: ">= 3.0.0"
---

# Pre-Compaction Save Skill

Automatically saves a structured session summary to engram before context compaction occurs, preserving critical context that would otherwise be lost.

## Triggers

- OMO `preemptive-compaction` hook (fires before compaction)
- DCP `compress` tool (when model initiates compression)
- Manual: `skill pre-compaction-save`

## What It Saves

1. **Session summary** via `engram mem_session_summary` — structured context for next session
2. **Pattern observation** via `engram mem_save` with `topic_key: pattern/pre-compaction-save` — evolving knowledge

## Configuration

No configuration required. Uses environment variables:
- `OPENCODE_PROJECT` — project name (default: basename of PWD)
- `OPENCODE_SESSION_ID` — session ID (default: timestamp)

## Installation

```bash
# Symlinked from dotfiles
stow --adopt -R -d ~/projects/personal/dotfiles/stow -t ~/.config/opencode opencode
```

## Files

- `pre-compaction-save.sh` — Main hook script (executable)
- `SKILL.md` — This manifest

## Integration

Add to OMO hooks in `oh-my-openagent.json`:
```json
{
  "hooks": {
    "pre_compaction_save": {
      "enabled": true,
      "command": "pre-compaction-save"
    }
  }
}
```