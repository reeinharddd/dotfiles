# THREAT_MODEL.md — Threat Model for Dotfiles + AI Harness

> **Scope**: This threat model covers the dotfiles repository, the AI agent harness (OpenCode + LiteLLM + plugins), and the bootstrap/deployment pipeline. It does NOT cover application code in other repos.

---

## 1. Assets & Trust Boundaries

| Asset | Type | Sensitivity | Trust Boundary |
|-------|------|-------------|----------------|
| `opencode.jsonc` | Config | Medium (model routing, provider endpoints) | User-only read/write |
| `.env.sops` / `secrets.conf.sops` | Encrypted secrets | **Critical** (API keys, tokens) | Encrypted at rest; decrypted only in user session |
| `age` private key (`~/.config/sops/age/keys.txt`) | Key material | **Critical** | **Never in repo**; local filesystem only (mode 600) |
| `bootstrap.sh` | Executable | High (runs with sudo) | Signed/verified via checksums; CI-tested |
| LiteLLM Proxy (`localhost:4000`) | Service | Medium (routes LLM traffic) | Loopback-only; no external exposure |
| OpenCode plugins | Code | High (runs in agent context) | Built from locked `package-lock.json`; reviewed in CI |
| GitHub Actions workflows | CI/CD | Medium (can push to repo) | Runs in isolated containers; no secrets in logs |
| `antigravity-accounts.json` | OAuth tokens | **Critical** (Google OAuth) | Gitignored; local only |

---

## 2. Threat Actors

| Actor | Motivation | Capability |
|-------|------------|------------|
| **Malicious npm package** (supply chain) | Steal keys, inject code | Publishes to npm; runs at install/build time |
| **Compromised LLM response** (prompt injection) | Exfiltrate data, run commands | Controls agent output; can request tool calls |
| **Local attacker** (physical/SSH) | Read secrets, persist | Filesystem access; can read decrypted `.env` |
| **Malicious GitHub Action** | Push to repo, steal secrets | Runs in CI context; has `GITHUB_TOKEN` |
| **Network MITM** (downloads) | Tamper with binaries | Intercepts HTTP; modifies `curl \| bash` payloads |

---

## 3. Attack Surface & Mitigations

### 3.1 Supply Chain (npm / PyPI / Docker)

| Vector | Mitigation |
|--------|------------|
| `opencode` plugins (`npm ci`) | `package-lock.json` committed; `npm ci` in bootstrap; no `@latest` in production |
| `mise` tools | Pinned versions in `mise.toml`; checksums verified |
| `lazydocker` / `mise` install scripts | Downloaded to `/tmp`, checksum verified before exec (stubs in bootstrap) |
| LiteLLM Docker image | Pinned by digest: `ghcr.io/berriai/litellm:main-v1.83.0@sha256:...` |
| GH Actions | Pinned action versions (e.g., `actions/checkout@v4`); no `uses: owner/repo@main` |

### 3.2 Prompt Injection / Agent Autonomy

| Vector | Mitigation |
|--------|------------|
| Agent reads `.env` / secrets | `envsitter-guard` plugin blocks `.env*` read/edit via tools; `bash` permission = `ask` + allowlist |
| Agent runs arbitrary `bash` | `bash` default = `ask`; allowlist: `mise, git, stow, npm, cargo, python3, node, gh, docker, systemctl, journalctl` |
| Agent writes to sensitive paths | `rm -rf`, `git reset --hard`, `find -delete` denied |
| Web fetch exfiltration | `webfetch` default = `ask` |
| Unbounded agent loops | `subagent_depth: 2`; `max_steps` via routing guard |

### 3.3 Secret Management

| Vector | Mitigation |
|--------|------------|
| API keys in repo history | Rotated; `.gitleaks.toml` with URL-token rules; CI blocks pushes with secrets |
| `FIRECRAWL_API_KEY` in URL | Moved to `{env:FIRECRAWL_API_KEY}` placeholder |
| `sudo` password | Removed from all files; `sudo -S` prompt or `sudoers NOPASSWD` for specific cmds |
| Taskwarrior encryption key | Encrypted with sops+age (`.sops.yaml`); age key never in repo |
| Daily backup push | Redirected to **private** repo (`DOTFILES_BACKUP_REMOTE`); public repo no longer auto-pushed |

### 3.4 CI/CD Pipeline

| Vector | Mitigation |
|--------|------------|
| Malicious PR modifies workflow | Required reviews; `pull_request` trigger only; no `workflow_dispatch` with secrets |
| Secrets in CI logs | No secrets in repo; `GITHUB_TOKEN` only; `gitleaks` scans on every push |
| Bootstrap not tested | CI runs `bootstrap.sh --dry-run` + `stow-sync.sh --dry-run` in clean container |

### 3.5 Network / LiteLLM Proxy

| Vector | Mitigation |
|--------|------------|
| LiteLLM exposed externally | Binds `127.0.0.1:4000` only; systemd `After=docker.service` |
| Master key leakage | `LITELLM_MASTER_KEY` from env (sops-decrypted); not in config |
| Model routing abuse | `router_settings: routing_strategy: usage-based-routing`; virtual keys with `max_budget` |

---

## 4. Residual Risks (Accepted)

| Risk | Reason | Monitoring |
|------|--------|------------|
| Age key on disk (`~/.config/sops/age/keys.txt`) | Required for decryption; mode 600; not in repo | File integrity via `aide`/`tripwire` (optional) |
| Decrypted `.env` in `$HOME` | Needed for runtime; cleared on logout? | Not auto-cleared; user responsibility |
| `antigravity` OAuth tokens | Google may ban accounts; fallback only | Not primary auth; `opencode-antigravity-auth` used as fallback |
| Prompt injection via MCP tools | MCP servers run with user perms | Only trusted MCP servers configured; no auto-approve |
| Bootstrap `curl \| bash` | Checksums not yet filled | **TODO**: Fill actual SHA256s before public use |

---

## 5. Incident Response

1. **Secret leaked in repo** → Immediately rotate key; `git filter-repo` or new repo; run `gitleaks` on all clones
2. **Agent exfiltrated data** → Check `bash`/`webfetch` audit logs; review Langfuse traces for anomalous tool calls
3. **Supply chain compromise** → `npm audit` / `mise outdated`; rebuild plugins from locked `package-lock.json`
4. **LiteLLM master key exposed** → Rotate `LITELLM_MASTER_KEY`; regenerate virtual keys
5. **Age key compromised** → Generate new key; re-encrypt all `.sops` files; update `.sops.yaml`

---

## 6. Verification Checklist (Pre-Release)

- [ ] `gitleaks detect --config .gitleaks.toml --source .` passes
- [ ] `shellcheck scripts/*.sh` passes
- [ ] `bootstrap.sh --dry-run` succeeds in clean container (CI)
- [ ] `stow-sync.sh --dry-run` produces no conflicts
- [ ] All `@latest` plugins pinned in `package.json`
- [ ] LiteLLM image pinned by digest in `litellm.service`
- [ ] Age key `~/.config/sops/age/keys.txt` mode 600, not in repo
- [ ] `DOTFILES_BACKUP_REMOTE` points to private repo
- [ ] No `sudo` password in any file
- [ ] No personal paths (`/home/reeinharrrd`) in any config

---

## 7. References

- [sops + age](https://github.com/getsops/sops#age)
- [envsitter-guard](https://github.com/envsitter/envsitter-guard)
- [LiteLLM Security](https://docs.litellm.ai/docs/proxy/security)
- [OpenCode Permissions](https://opencode.ai/docs/permissions)
- [Gitleaks Config](https://github.com/gitleaks/gitleaks#configuration)