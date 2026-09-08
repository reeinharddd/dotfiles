---
description: Run all gates before declaring a task release-ready
---

# Release Check

Run `~/.config/opencode/scripts/opencode-release-check "$PWD"`.

This is a read-only gate. It does not commit, push, deploy, reset, or clean the worktree.
The task packet must be marked `verified` or `completed` after the evidence has been reviewed.
