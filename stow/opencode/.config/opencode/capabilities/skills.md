# Skills — 24 core + bodega on-demand

> Core skills load at startup (allowlist in `regenerate-manifests.py` → `CORE_SKILL_NAMES`).
> Bodega skills (~1280) are discoverable but NOT loaded — invoke on demand via `skill(name=...)`.

## 24 Core Skills (always available)
| Skill | Trigger / What it does |
|-------|------------------------|
| `core-constitution` | Karpathy 12 rules + values. Loaded every session (immune to override). |
| `system-context` | Loads full machine context (OS, hardware, tools, config). |
| `project-auto-detect` | Detect stack/language/framework/test-runner of cwd; load project AGENTS.md. |
| `skill-router` | Lazy router — routes to a domain skill, or `capability-scanner`. |
| `capability-scanner` | Discover unregistered skills/MCPs/binaries in the system. |
| `brainstorming` | Explore intent/requirements/design BEFORE creative implementation. |
| `writing-plans` | Write a multi-step implementation plan before touching code. |
| `code-architect` | Design feature architecture from existing patterns; blueprint. |
| `code-explorer` | Deep-trace an existing feature (execution paths, layers, deps). |
| `feature-dev` | 7-phase feature workflow (explore → clarify → architect → build → review). |
| `systematic-debugging` | Hypothesis-driven debugging loop (≥3 hypotheses, verify root cause). |
| `test-driven-development` | Red-green-refactor; write tests before implementation. |
| `code-reviewer` | High-confidence bug/logic/security review of small diffs. |
| `security-review` | Focused security audit of pending changes (real exploitability). |
| `verification-before-completion` | Evidence before success claims; run verification commands. |
| `dispatching-parallel-agents` | Fan out 2+ independent tasks to parallel subagents. |
| `executing-plans` | Execute a written plan with review checkpoints. |
| `finishing-a-development-branch` | Present merge/PR/cleanup options when work completes. |
| `handoff` | Compact conversation into a handoff doc for another agent. |
| `error-handling` | Robust error patterns (typed errors, retries, circuits, messages). |
| `benchmark` | Measure perf baselines / regressions / stack alternatives. |
| `auto-extract` | DCP — distill large tool outputs (>3000 chars) to save tokens. |
| `auto-protect-wrap` | DCP — wrap high-value outputs in `<protect>` for compression. |
| `pre-compaction-save` | Auto-save session summary to engram before compaction. |

## Manifest-only entries (no `skills/` dir)
`caveman`, `transcribe`, `watch-video`, `security-review` (alias of security-research) appear in
the global manifest via third-party symlinks / aliases but have no dedicated core dir. They are
invocable; this doc tracks the 24 canonical dirs.

## On-Demand (bodega, ~1280)
- Registered via `bodega-ondemand-*.json` manifests; NOT in context until invoked.
- Invoke: `skill(name="<name>")` when a task matches its description.
- Examples: `frontend-design`, `mcp-builder`, `skill-creator`, `tdd`, `react-build`, `go-test`,
  `rust-build`, `python-review`, `kotlin-*`, `flutter-*`, `orchestrate`, `multi-*`, etc.
- **Never** preload the full bodega. Search first (`capability-scanner` / `skill-router`).

## Storage decision rule (own / third-party / modified)
- **Own skill** → author in `stow/opencode/.config/opencode/skills/`, symlink via stow.
- **Third-party, unmodified** → reference in place (clone lives in `~/tools/`); never copy.
- **Third-party, locally modified** → copy into stow, break the link (don't dirty their repo).
- Generated artifacts (bodega manifests, node_modules, codegraph indexes) are build outputs —
  generated in place, never symlinked.
- Repos in `~/tools/` can change upstream → run `regenerate-manifests.py --check` to detect
  dead paths; `--dry-run` before writing.

## Best practices
- Load a skill when the task matches its description — don't reinvent the workflow.
- For creative work, `brainstorming` first; for multi-file features, `feature-dev`.
- For bugs, `systematic-debugging` before proposing fixes.
- Keep core skills as the default toolkit; reach into bodega only when needed.
