# Quality Gates — Mandatory Pre-Completion Checks

> ALWAYS LOADED — verify these before declaring anything "done".

## Before Claiming Done

Run these in order (the global scripts select checks from the detected stack):
1. **LSP diagnostics**: `lsp_diagnostics` for all changed files — must be clean (0 errors)
2. **Verification**: `~/.config/opencode/scripts/opencode-verify "$PWD" --run-tests`
3. **Security**: `~/.config/opencode/scripts/opencode-security-audit "$PWD"`
4. **Build**: project must build/compile with 0 errors when a build exists
5. **Format**: code must be formatted (run formatter if needed)
6. **Review diff**: `git diff` and check for:
   - Debug code left behind (console.log, print, dbg!)
   - TODO/FIXME/HACK comments you added
   - Dead code / commented-out blocks
   - Secrets or debugging artifacts

Reports are written to `.opencode/artifacts/`; attach their paths to the task packet.

## After 3 Fails

STOP → REVERT → DOCUMENT → CONSULT ORACLE
- Revert changes via `git checkout` or undo
- Document what was attempted and what failed (save to engram)
- Delegate to oracle agent with full failure context

## Memory Protocol
- Save to Engram AFTER EVERY:
  - Bug fix (what broke, why, how fixed)
  - Architecture decision (what, why, trade-offs)
  - Non-obvious discovery (gotchas, edge cases)
  - Pattern or convention established
  - Configuration change
- Format: **What** | **Why** | **Where** | **Learned**

## End-of-Session Protocol
Before ending ANY session:
1. Call `engram mem_session_summary` with structured summary
2. Include: Goal, Discoveries, Accomplished, Next Steps, Relevant Files
3. Include any user preferences or constraints discovered
