# 03-quality-gates.md — Quality Gates (condensed)

> Category: QUALITY | Authority: Global Harness Contract §Completion. ALWAYS LOADED — verification before asserting done.

## Gates (ALL must pass)
1. **LSP Diagnostics**: `lsp_diagnostics` clean on changed files
2. **Build**: exit code 0 (if applicable)
3. **Tests**: pass (or explicit note of pre-existing failures)
4. **Shellcheck**: `shellcheck scripts/*.sh` clean
5. **Gitleaks**: `gitleaks detect --no-git` clean on HEAD
6. **Verify-Claims**: threat model claims verified
7. **Context Budget**: `scripts/ctx-budget` ≤ 15 KB

## Verification Protocol
- Run `lsp_diagnostics` on EVERY changed file after edit
- Run build/test commands for the project
- Run `scripts/ctx-budget` before declaring done
- Run `gitleaks detect --no-git` on current HEAD
- Run `scripts/verify-claims.sh` if threat model changed

## Evidence Before Assertions
- No "should work" without verification
- Read actual command output, don't skim
- If delegated, read EVERY file the subagent touched
- After 3 fails: STOP → REVERT → DOCUMENT → ORACLE

## Anti-Patterns
- ❌ Skipping LSP diagnostics
- ❌ Batch-completing todos
- ❌ Finishing without completing todos
- ❌ "This should work" without running verification
- ❌ Deleting failing tests to pass