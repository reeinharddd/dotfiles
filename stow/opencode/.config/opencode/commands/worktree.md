---
description: Plan or create an isolated git worktree for a task.
---

Plan first:

```bash
~/.config/opencode/scripts/opencode-worktree "$PWD" --name "$ARGUMENTS"
```

Create only after the task packet and scope are clear:

```bash
~/.config/opencode/scripts/opencode-worktree "$PWD" --name "$ARGUMENTS" --create
```

Never reset, clean, or copy dirty changes automatically.
