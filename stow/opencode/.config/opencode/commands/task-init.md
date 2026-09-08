---
description: Create a durable project task packet without overwriting existing state.
---

Create the task packet before non-trivial work:

```bash
~/.config/opencode/scripts/opencode-task init "$PWD" --title "$ARGUMENTS" --kind implementation
```

If a packet already exists, inspect it and continue it; never overwrite it.
