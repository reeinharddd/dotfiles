# Reproducibility — OLA 13

> Category: SYSTEM DOCUMENTATION (capability reference, not behavioral authority).
> **Structural validation**: `scripts/validate-harness-registry.py` (OLA 12).
> **Bootstrap**: `bootstrap.sh` (root of dotfiles repo).

## @latest scan results (filtered)

Scanned `stow/opencode/.config/opencode/` excluding `node_modules/`, `log/`, `storage/`, `.git/`, `implementation-v1/baseline/`, and historical docs.

| Hit | File | Classification | Action |
|-----|------|----------------|--------|
| `package-lock.json:3407` | lockfile metadata | Stale deprecation notice (uuid@10 sub-dep) | **Leave** — not active config |
| `capabilities/mcps.md:32` | docs | Anti-pattern reference ("Never `@latest`") | **Leave** — documentation |
| `capabilities/plugins.md:11,75` | docs | Anti-pattern reference ("pin version, no `@latest`") | **Leave** — documentation |
| `scripts/patch-morph-plugin.sh:35` | active script | Cache path `@morphllm/opencode-morph-plugin@latest` | **Fixed** — removed `@latest` entry |

**Result: 0 active `@latest` violations in live config paths.**

## npm ci coherence

- `package.json` and `package-lock.json` are coherent — `npm install --package-lock-only --dry-run` reports "up to date".
- All active deps are pinned with exact versions or caret ranges already resolved in lockfile.
- Engine warning for `@opentui/core@0.5.11` (requires node>=26.4.0, current v24.21.0) is a runtime compatibility notice, not a lock mismatch.
- No `@latest` in any `plugin[]`, `npx` pin, or `package.json` dependency version.

## Reproducible bootstrap path

```
git clone https://github.com/reeinharddd/dotfiles.git ~/projects/personal/dotfiles
cd ~/projects/personal/dotfiles
./bootstrap.sh                          # full bootstrap (system deps, stow, npm ci, validate)
# or step-by-step:
./scripts/stow-sync.sh                  # symlink configs via stow
cd stow/opencode/.config/opencode
npm ci                                  # install pinned npm deps
python3 scripts/validate-harness-registry.py  # structural contract validation
opencode debug config                   # smoke test
```

### What `bootstrap.sh` does

1. Preflight (OS check, apt install essentials)
2. Install Ghostty, mise, cargo tools, lazydocker
3. Clone dotfiles repo (if not present)
4. `./scripts/stow-sync.sh` — symlink all stow packages
5. `npm ci` + `npm run build` for opencode plugins
6. `python3 scripts/validate-harness-registry.py` — harness structural validation
7. Decrypt sops secrets (if available)
8. Set zsh as default shell, Ghostty as default terminal

### `just sync` shortcut

```
just sync    # runs stow-sync.sh then stow-check.sh (simulation)
```

For full bootstrap including npm ci and validator, use `./bootstrap.sh`.

## Intentionally floating vs pinned

| Item | Status | Reason |
|------|--------|--------|
| `plugin[]` entries | Pinned (exact or caret) | OLA 07: no `@latest` |
| `npx` MCP pins | Pinned via `harness-registry.jsonc` `pinnedTools` | OLA 07: single version authority |
| `@morphllm/opencode-morph-plugin` | Pinned `^2.0.16` | Fixed in `package.json` |
| `@opentui/core` | Pinned `0.5.11` | Engine mismatch noted but lock coherent |
| `opencode-yaml-hooks` | Pinned `^2026.3.29` | Date-based version, intentional |

## Validation commands

```bash
# Structural contract validation
python3 scripts/validate-harness-registry.py

# npm coherence check
cd stow/opencode/.config/opencode && npm install --package-lock-only --dry-run

# @latest scan (filtered)
rg '@latest' stow/opencode/.config/opencode/ -l \
  --no-ignore --hidden \
  -g '!node_modules/' -g '!log/' -g '!storage/' -g '!.git/' \
  -g '!implementation-v1/baseline/'

# Full bootstrap dry-run
just sync          # stow simulation
```
