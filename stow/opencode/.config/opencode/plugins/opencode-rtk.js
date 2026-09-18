/**
 * opencode-rtk.js — read-path guard for bash (RTK rewrite is NOT possible here)
 *
 * Enforces the user rule: bash must not be used for file reads
 * (cat/ls/rg/grep/head/tail/sed/awk/find) — use read/grep/glob instead.
 * Violations abort the tool call with a guiding error.
 *
 * Why this file no longer rewrites git/gh -> rtk:
 *   opencode 1.18.29 `tool.execute.before` can OBSERVE tool args, but its
 *   mutations are ignored — neither `output.args.command = ...`, a full
 *   `output.args = {...}` reassignment, nor `output.output = ...` changes what
 *   executes (verified 2026-09-17 with an observable `echo` marker). The ONLY
 *   mechanism that aborts a call is THROWING from the hook — which is what the
 *   guard below does. Git/gh -> rtk rewriting must come from rtk's own shell
 *   hook / PATH shim, NOT from this plugin.
 *
 * Fail-open: unexpected errors are logged to .rtk-stats.jsonl and the call
 * proceeds untouched. Only an explicit read-tool violation blocks.
 */

import fs from "fs";

const STATS_FILE = "/home/reeinharrrd/.config/opencode/.rtk-stats.jsonl";
const READ_TOOLS = ["cat", "ls", "rg", "grep", "head", "tail", "sed", "awk", "find"];
// opencode prepends `export VAR=... ...;` to some bash calls (semicolon-separated).
const PREAMBLE = /^(export\s[\s\S]*?(?:;\s*|&&\s*))/;
// Escape hatch: pipelines / redirections / heredocs / substitutions are allowed
// (only plain `cat file`-style reads are blocked, so heredocs and pipes survive).
const COMPLEX = /[|<>]|\$\(|`/;
const TAG = "[opencode-rtk]";

function log(entry) {
  try {
    fs.appendFileSync(STATS_FILE, JSON.stringify({ ts: Date.now(), ...entry }) + "\n");
  } catch {
    /* stats are best-effort, never break the flow */
  }
}

export default async function opencodeRtk() {
  return {
    "tool.execute.before": async (input, output) => {
      try {
        if (!input || input.tool !== "bash") return;
        const raw = output?.args?.command;
        if (!raw || typeof raw !== "string") return;

        const m = raw.match(PREAMBLE);
        const core = (m ? raw.slice(m[1].length) : raw).trim();
        if (!core) return;

        const first = core.split(/\s+/)[0] || "";
        if (!READ_TOOLS.includes(first)) return;

        if (COMPLEX.test(core)) {
          log({ type: "allow_complex", command: core });
          return;
        }

        log({ type: "block", command: core });
        throw new Error(
          `${TAG} bash "${first}" bloqueado: usa read/grep/glob (reglas del usuario). Comando: ${core}`,
        );
      } catch (err) {
        if (String(err?.message ?? err).includes(TAG)) throw err;
        log({ type: "error", message: String(err) });
      }
    },
  };
}
