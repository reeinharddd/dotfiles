/**
 * opencode-rtk.js — RTK rewrite + read-path invariant
 *
 * Rewrites slow native git/gh calls into rtk (RTK: faster git/gh via hook-cached
 * runtimes; verifiable with `rtk gain`). Blocks bash-level read paths that
 * duplicate dedicated tools (read/grep/glob) per user rules.
 *
 * Fail-open: any error in this plugin logs to .rtk-stats.jsonl and lets the
 * original tool call proceed untouched. Never blocks unless the rule matches.
 */

import fs from "fs";

const STATS_FILE = "/home/reeinharrrd/.config/opencode/.rtk-stats.jsonl";
const READ_TOOLS = ["cat", "ls", "rg", "grep", "head", "tail", "sed", "awk", "find"];
const GIT_PREFIX = /^(?:git\s+(?:status|diff|log|stash)\b)/;
const GH_PREFIX = /^(?:gh\s+pr\s+(?:view|list|diff)\b)/;

function log(entry) {
  try {
    fs.appendFileSync(STATS_FILE, JSON.stringify({ ts: Date.now(), ...entry }) + "\n");
  } catch {
    /* stats are best-effort, never break the flow */
  }
}

export default async function opencodeRtk() {
  return {
    // Rewrite git/gh -> rtk before execution
    "tool.execute.before": async (input, output) => {
      try {
        if (!input || input.tool !== "bash") return;
        const cmd = input.input?.command ?? "";
        if (!cmd || typeof cmd !== "string") return;

        if (GIT_PREFIX.test(cmd) || GH_PREFIX.test(cmd)) {
          const rewritten = "rtk " + cmd;
          log({ type: "rewrite", from: cmd, to: rewritten });
          input.input.command = rewritten;
          return;
        }

        const first = cmd.trim().split(/\s+/)[0] || "";
        if (READ_TOOLS.includes(first)) {
          log({ type: "block", command: cmd });
          output.output = `[opencode-rtk] ${first} via bash bloqueado: usa read/grep/glob (reglas del usuario). Comando: ${cmd}`;
          return; // setting output aborts execution and uses this as the tool result
        }
      } catch (err) {
        log({ type: "error", message: String(err) });
      }
    },
  };
}