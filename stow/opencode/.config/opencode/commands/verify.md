---
description: Run the global stack-aware verification and security gates
---

# Verify Command

Run the global verification loop for the current project: $ARGUMENTS

1. Run `~/.config/opencode/scripts/opencode-verify "$PWD" --run-tests`.
2. Run `~/.config/opencode/scripts/opencode-security-audit "$PWD"`.
3. Run project-specific checks only when their manifest or documentation confirms they apply.

Reports are stored under `.opencode/artifacts/`. Review failures before declaring the task done.
