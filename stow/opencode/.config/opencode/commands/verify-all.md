---
description: Run the global stack-aware verification gates and save evidence.
---

Run:

```bash
~/.config/opencode/scripts/opencode-verify "$PWD" --run-tests
```

For a fast non-test pass, omit `--run-tests`. Treat the generated report as evidence, not as a
replacement for reviewing failures.
