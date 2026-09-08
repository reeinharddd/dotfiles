---
name: handoff
description: "Compresses current session into a structured markdown document for continuing in a fresh session or passing to another agent."
---

# Handoff Skill

When this skill is triggered (manually or at session end):

1. Compress session into structured markdown:
   - Goal, Status, Key decisions, Files changed, Next steps, Context

2. Save to .opencode/handoff.md for next session.
