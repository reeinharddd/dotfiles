#!/usr/bin/env python3
"""Regenerate all 5 bodega manifests under ~/.config/opencode/plugins/

Scans ~/tools/ for skills (SKILL.md dirs), agents (.md in agents/ dirs),
and commands (.md files in commands/ dirs), then classifies:

  CORE (global, always available):
    - ECC/skills/ (English only, not docs/locales)
    - ECC/agents/ (English only, not docs/locales)
    - ~/tools/skills/ (the fundamentals)

  BODEGA (ondemand, per-project discoverable):
    - Everything else: hidden dir skills (.kiro/.cursor/.claude/.opencode),
      locale copies, other repos' skills, all commands, all non-core agents

Hidden dirs scanned:
  .claude, .opencode, .codex, .kiro, .cursor, .windsurf, .github

Usage:
  python3 regenerate-manifests.py            # normal: scan + write
  python3 regenerate-manifests.py --dry-run   # scan only, no write
  python3 regenerate-manifests.py --check     # validate existing manifests only

Idempotent and safe to re-run.
"""

import json, os, hashlib, sys, argparse

TOOLS = "/home/reeinharrrd/tools"
PLUGINS = "/home/reeinharrrd/.config/opencode/plugins"

# Hidden dirs we ALLOW traversal into (others like .git, node_modules skipped)
ALLOW_HIDDEN = {
    ".claude",
    ".opencode",
    ".codex",
    ".kiro",
    ".cursor",
    ".windsurf",
    ".github",
}
# Dirs ALWAYS skipped
SKIP_DIRS = {
    ".git",
    "node_modules",
    ".venv",
    "__pycache__",
    ".bun",
    "dist",
    "build",
    "target",
    ".angular",
}

# ── helpers ──────────────────────────────────────────────────────────


def read_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return []


def write_json(path, data):
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
    print(f"  wrote {len(data)} entries -> {path}")


def should_enter_dir(name):
    """Return True if we should recurse into this directory."""
    if name.startswith("."):
        return name in ALLOW_HIDDEN
    if name in SKIP_DIRS:
        return False
    return True


def find_skill_dirs(roots):
    """Walk dirs (including allowed hidden), yield any dir containing SKILL.md."""
    seen = set()
    for root in roots:
        if not os.path.isdir(root):
            continue
        stack = [root]
        while stack:
            d = stack.pop()
            if not os.path.isdir(d):
                continue
            try:
                ents = os.listdir(d)
            except PermissionError:
                continue
            if "SKILL.md" in ents:
                real = os.path.realpath(d)
                if real not in seen:
                    seen.add(real)
                    yield d
                continue  # don't descend into a skill dir
            for e in ents:
                if should_enter_dir(e):
                    full = os.path.join(d, e)
                    if os.path.isdir(full):
                        stack.append(full)


def find_agent_files(roots):
    """Walk dirs, yield .md files inside dirs named 'agents'."""
    seen = set()
    for root in roots:
        if not os.path.isdir(root):
            continue
        stack = [root]
        while stack:
            d = stack.pop()
            if not os.path.isdir(d):
                continue
            try:
                ents = os.listdir(d)
            except PermissionError:
                continue
            basename = os.path.basename(d)
            is_agents_dir = basename == "agents"
            for e in ents:
                full = os.path.join(d, e)
                if os.path.isdir(full):
                    if should_enter_dir(e):
                        stack.append(full)
                elif is_agents_dir and e.endswith(".md"):
                    real = os.path.realpath(full)
                    if real not in seen:
                        seen.add(real)
                        yield full


def find_command_dirs(roots):
    """Find dirs named 'commands' containing .md files."""
    seen = set()
    for root in roots:
        if not os.path.isdir(root):
            continue
        stack = [root]
        while stack:
            d = stack.pop()
            if not os.path.isdir(d):
                continue
            try:
                ents = os.listdir(d)
            except PermissionError:
                continue
            basename = os.path.basename(d)
            if basename == "commands":
                has_md = any(e.endswith(".md") for e in ents)
                if has_md:
                    real = os.path.realpath(d)
                    if real not in seen:
                        seen.add(real)
                        yield d
                continue  # don't descend deeper into commands dir
            for e in ents:
                if should_enter_dir(e):
                    full = os.path.join(d, e)
                    if os.path.isdir(full):
                        stack.append(full)

def find_command_files(roots):
    """Walk dirs, yield .md files inside dirs named 'commands'."""
    seen = set()
    for root in roots:
        if not os.path.isdir(root):
            continue
        stack = [root]
        while stack:
            d = stack.pop()
            if not os.path.isdir(d):
                continue
            try:
                ents = os.listdir(d)
            except PermissionError:
                continue
            basename = os.path.basename(d)
            if basename == "commands":
                for e in ents:
                    if e.endswith(".md"):
                        full = os.path.join(d, e)
                        real = os.path.realpath(full)
                        if real not in seen:
                            seen.add(real)
                            yield full
                continue
            for e in ents:
                if should_enter_dir(e):
                    full = os.path.join(d, e)
                    if os.path.isdir(full):
                        stack.append(full)

def dedup_paths(paths):
    """Dedup by realpath, preserving order, return sorted."""
    seen = set()
    out = []
    for p in paths:
        r = os.path.realpath(p)
        if r not in seen:
            seen.add(r)
            out.append(p)
    return sorted(out)


def validate_entries(entries, label):
    """Check all paths exist. Returns (ok_count, bad_count)."""
    bad = [p for p in entries if not os.path.exists(p)]
    if bad:
        print(f"  {label}: {len(bad)} paths do not exist on disk!", file=sys.stderr)
        for p in bad[:5]:
            print(f"    MISSING: {p}", file=sys.stderr)
        if len(bad) > 5:
            print(f"    ... and {len(bad) - 5} more", file=sys.stderr)
    return len(entries) - len(bad), len(bad)


# ── CORE classification ─────────────────────────────────────────────


def is_core_skill(p):
    """Determine if a skill belongs in core (always available).
    
    Uses an explicit allowlist of truly universal skill names.
    Everything else → bodega.
    """
    name = os.path.basename(p.rstrip("/"))
    CORE_SKILL_NAMES = {
        "system-context", "core-constitution", "project-auto-detect",
        "skill-router", "capability-scanner",
        "brainstorming", "writing-plans", "code-architect", "code-explorer",
        "feature-dev", "systematic-debugging", "test-driven-development",
        "code-reviewer", "security-review", "verification-before-completion",
        "dispatching-parallel-agents", "executing-plans",
        "finishing-a-development-branch", "handoff",
        "error-handling", "benchmark",
        "stop-slop", "auto-extract", "auto-protect-wrap", "pre-compaction-save",
    }
    return name in CORE_SKILL_NAMES


def is_core_agent(p):
    """Determine if an agent belongs in core."""
    real = os.path.realpath(p)
    # ECC English agents under ECC/agents/ (NOT docs/, NOT locale)
    if "/ECC/agents/" in real and "/docs/" not in real:
        return True
    return False

def is_core_command(p):
    """Determine if a command belongs in core (always available).
    Uses an explicit allowlist of universal command names.
    """
    name = os.path.basename(p.rstrip("/")).replace(".md", "")
    CORE_COMMAND_NAMES = {
        "aside", "build-fix", "checkpoint", "code-review",
        "code-architect", "code-explorer", "code-reviewer", "e2e",
        "eval", "feature-dev", "frontend-design", "gan-build", "gan-design",
        "harness-audit", "loop-start", "loop-status", "mcp-builder",
        "multi-backend", "multi-execute", "multi-frontend", "multi-plan", "multi-workflow",
        "orchestrate", "plan", "plan-prd", "pr",
        "quality-gate", "refactor-clean", "resume-session", "review-pr",
        "santa-loop", "save-session", "security", "security-review", "security-scan",
        "sessions", "tdd", "test-coverage", "verify",
        "agents-md-improver", "agents-md-revise",
    }
    return name in CORE_COMMAND_NAMES

# ── collect scan roots ──────────────────────────────────────────────


def get_scan_roots():
    """Build list of all directories to scan."""
    roots = set()
    for repo in sorted(os.listdir(TOOLS)):
        rp = os.path.join(TOOLS, repo)
        if os.path.isdir(rp) and not repo.startswith("."):
            roots.add(rp)

    # ECC docs/locales — also scan for skills nested inside
    ecc_docs = os.path.join(TOOLS, "ECC", "docs")
    if os.path.isdir(ecc_docs):
        for lang in sorted(os.listdir(ecc_docs)):
            roots.add(os.path.join(ecc_docs, lang))

    # Specific sub-dirs for plugins that have depth
    extras = [
        (TOOLS, "agentmemory", "plugin"),
        (TOOLS, "caveman", "plugins"),
        (TOOLS, "caveman", "skills"),
        (TOOLS, "engram", "plugin"),
        (TOOLS, "engram", "skills"),
        (TOOLS, "claude-skills", "skills"),
        (TOOLS, "feynman", "skills"),
        (TOOLS, "gstack"),
    ]
    for parts in extras:
        p = os.path.join(*parts)
        if os.path.isdir(p):
            roots.add(p)

    # gentle-ai internals
    ga_base = os.path.join(TOOLS, "gentle-ai")
    for sub in [
        "internal/assets",
        "internal/assets/claude",
        "internal/assets/cursor",
        "internal/assets/kimi",
        "internal/assets/kiro",
    ]:
        p = os.path.join(ga_base, sub)
        if os.path.isdir(p):
            roots.add(p)

    # oh-my-openagent
    oho = os.path.join(TOOLS, "oh-my-openagent")
    for sub in [
        "packages/omo-codex/plugin",
        "packages/omo-codex/plugin/components/ultrawork",
        "packages/omo-opencode/src/features/builtin-skills",
        "packages/shared-skills/skills",
    ]:
        p = os.path.join(oho, sub)
        if os.path.isdir(p):
            roots.add(p)

    # ClawTeam docs
    ct = os.path.join(TOOLS, "ClawTeam-OpenClaw", "docs", "skills")
    if os.path.isdir(ct):
        roots.add(ct)

    # ECC legacy shims
    legacy = os.path.join(TOOLS, "ECC", "legacy-command-shims")
    if os.path.isdir(legacy):
        roots.add(legacy)
    # OpenCode core skills symlinks (dotfiles-managed)
    core_symlinks = "/home/reeinharrrd/.config/opencode/skills"
    if os.path.isdir(core_symlinks):
        roots.add(core_symlinks)

    return sorted(roots)


# ── manifest file names ─────────────────────────────────────────────

MANIFEST_FILES = [
    "bodega-global-skills.json",
    "bodega-ondemand-skills.json",
    "bodega-global-agents.json",
    "bodega-ondemand-agents.json",
    "bodega-global-commands.json",
    "bodega-ondemand-commands.json",
]


# ── main ─────────────────────────────────────────────────────────────


def main():
    parser = argparse.ArgumentParser(
        description="Regenerate bodega manifests from ~/tools/"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Scan and report only, don't write files",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Validate existing manifests only (no scan)",
    )
    args = parser.parse_args()

    # ── --check mode ─────────────────────────────────────────────

    if args.check:
        print("=== Validating existing manifests ===\n")
        all_ok = True
        for fname in MANIFEST_FILES:
            fpath = os.path.join(PLUGINS, fname)
            entries = read_json(fpath)
            ok, bad = validate_entries(entries, fname)
            if bad:
                all_ok = False
        if all_ok:
            print("\nAll manifests clean.")
        sys.exit(0 if all_ok else 1)

    # ── Scan mode ────────────────────────────────────────────────

    scan_roots = get_scan_roots()

    print(f"Scanning from {len(scan_roots)} root dirs...")

    print("Finding skills...")
    all_skills = dedup_paths(find_skill_dirs(scan_roots))
    print(f"  found {len(all_skills)} skill dirs")

    print("Finding agents...")
    all_agents = dedup_paths(find_agent_files(scan_roots))
    print(f"  found {len(all_agents)} agent files")

    print("Finding commands...")
    all_commands = dedup_paths(find_command_files(scan_roots))
    print(f"  found {len(all_commands)} command files")

    # ── Classify CORE vs BODEGA ──────────────────────────────────

    # Core skills: name-based allowlist, dedup by name (pick first)
    names_seen = set()
    core_skills = []
    for p in sorted(all_skills):
        if is_core_skill(p):
            name = os.path.basename(p.rstrip("/"))
            if name not in names_seen:
                names_seen.add(name)
                core_skills.append(p)
    bodega_skills = sorted(p for p in all_skills if p not in set(core_skills))

    core_agents = sorted(p for p in all_agents if is_core_agent(p))
    bodega_agents = sorted(p for p in all_agents if not is_core_agent(p))
    core_commands = sorted(p for p in all_commands if is_core_command(p))
    bodega_commands = sorted(p for p in all_commands if not is_core_command(p))

    print(f"\nClassification:")
    print(f"  core skills:   {len(core_skills)}")
    print(f"  bodega skills: {len(bodega_skills)}")
    print(f"  core agents:   {len(core_agents)}")
    print(f"  bodega agents: {len(bodega_agents)}")
    print(f"  core commands: {len(core_commands)}")
    print(f"  bodega commands: {len(bodega_commands)}")

    # ── Pre-write validation (safeguard) ─────────────────────────

    precheck_bad = 0
    for label, entries in [
        ("core_skills", core_skills),
        ("bodega_skills", bodega_skills),
        ("core_agents", core_agents),
        ("bodega_agents", bodega_agents),
        ("core_commands", core_commands),
        ("bodega_commands", bodega_commands),
    ]:
        ok, bad = validate_entries(entries, label)
        precheck_bad += bad

    if precheck_bad > 0:
        print(
            f"\n❌ {precheck_bad} items have broken paths.",
            file=sys.stderr,
        )
        if args.dry_run:
            print("   Dry-run: no files written.")
            sys.exit(1)
        response = input("   Write manifests anyway? [y/N] ")
        if response.lower() != "y":
            print("   Aborted.")
            sys.exit(1)

    # ── Write manifests (or dry-run) ─────────────────────────────

    if args.dry_run:
        print("\n=== DRY-RUN: no files written ===")
    else:
        write_json(os.path.join(PLUGINS, "bodega-global-skills.json"), core_skills)
        write_json(os.path.join(PLUGINS, "bodega-ondemand-skills.json"), bodega_skills)
        write_json(os.path.join(PLUGINS, "bodega-global-agents.json"), core_agents)
        write_json(os.path.join(PLUGINS, "bodega-ondemand-agents.json"), bodega_agents)
        write_json(os.path.join(PLUGINS, "bodega-global-commands.json"), core_commands)
        write_json(
            os.path.join(PLUGINS, "bodega-ondemand-commands.json"),
            bodega_commands,
        )

    # ── Summary ──────────────────────────────────────────────────

    print(f"\n{'=' * 60}")
    print(f"SUMMARY")
    print(f"  {'global-skills':30s} {len(core_skills):>5d} (core, always available)")
    print(f"  {'global-agents':30s} {len(core_agents):>5d} (core, always available)")
    print(f"  {'ondemand-skills':30s} {len(bodega_skills):>5d} (bodega, per-project)")
    print(f"  {'ondemand-agents':30s} {len(bodega_agents):>5d} (bodega, per-project)")
    print(f"  {'global-commands':30s} {len(core_commands):>5d} (core, always available)")
    print(
        f"  {'ondemand-commands':30s} {len(bodega_commands):>5d} (bodega, per-project)"
    )
    print(f"{'=' * 60}")
    print("Done! Re-run after adding repos to ~/tools/")


if __name__ == "__main__":
    main()
