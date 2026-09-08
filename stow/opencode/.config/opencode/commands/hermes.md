---
description: Delegate a task to the Hermes personal assistant (24/7 agent) from opencode
---

# Hermes

Run the local Hermes agent headless with the user's request and return its output.

## Usage

```bash
export PATH="$HOME/.local/bin:$PATH"
hermes -z "$ARGUMENTS"
```

## Rules

- Use for personal-assistant scope: reminders, drafts, message summaries, scheduled ideas, non-code errands.
- Do NOT use for codebase work — handle that directly in this session.
- If hermes is slow (>2 min), report that it runs async and offer `hermes cron` for recurring versions of the request.
- Long outputs: summarize; the full result stays in the hermes session log.
