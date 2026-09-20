/**
 * opencode-telemetry.js — event ledger for observability (v2, 2026-09-17)
 *
 * Records structured events to ~/.local/share/opencode/telemetry/events/YYYY-MM-DD.jsonl
 * (LOCAL date) so failures, delegations, and tool activity are debuggable after the fact.
 * Events: boot (plugin load + cwd + agent count), tool (name, args, ok/fail),
 * delegation (delegate/task calls incl. run_in_background), session.idle, plugin_error.
 *
 * Fail-open: any error is swallowed; never blocks or alters tool execution.
 * Hooks verified against opencode 1.18.29: config, tool.execute.before, session.idle.
 */

import fs from "fs";
import path from "path";

const TELEMETRY_DIR = path.join(
  process.env.HOME || "/home/reeinharrrd",
  ".local/share/opencode/telemetry",
  "events"
);

function localDay() {
  const d = new Date();
  const p = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

function log(entry) {
  try {
    fs.mkdirSync(TELEMETRY_DIR, { recursive: true });
    const file = path.join(TELEMETRY_DIR, localDay() + ".jsonl");
    fs.appendFileSync(file, JSON.stringify({ ts: new Date().toISOString(), ...entry }) + "\n");
  } catch {
    /* telemetry is best-effort, never break the flow */
  }
}

function truncate(value, max = 400) {
  try {
    const s = typeof value === "string" ? value : JSON.stringify(value);
    return s && s.length > max ? s.slice(0, max) + "…" : value;
  } catch {
    return undefined;
  }
}

function summarizeArgs(input) {
  try {
    const args = input?.args ?? input?.input ?? input?.parameters ?? {};
    return truncate(args);
  } catch {
    return undefined;
  }
}

export default async function opencodeTelemetry() {
  return {
    // Boot marker: fires when plugins are wired into config
    config: async (config) => {
      log({
        type: "boot",
        plugin: "opencode-telemetry",
        cwd: process.cwd(),
        agentCount: config?.agent ? Object.keys(config.agent).length : undefined,
      });
    },

    // Tool execution ledger: name, args (truncated), and success/failure
    "tool.execute.before": async (input, output) => {
      try {
        if (!input || typeof input.tool !== "string") return;
        if (process.env.OPENCODE_TELEMETRY_DUMP === "1") {
          log({
            type: "dump",
            input: truncate(input, 800),
            output: truncate(output, 800),
          });
        }
        const ok = !output || !output.isError;
        const entry = {
          type: "tool",
          tool: input.tool,
          sessionID: input.sessionID,
          callID: input.callID,
          ok,
          args: summarizeArgs(output),
        };
        if (!ok && output?.error) entry.error = String(output.error).slice(0, 500);
        log(entry);

        // Delegation visibility: flag run_in_background for post-hoc debugging
        if (input.tool === "delegate" || input.tool === "task") {
          const a = output?.args ?? output?.input ?? {};
          log({
            type: "delegation",
            tool: input.tool,
            background: Boolean(a.run_in_background),
            agent: a.agent ?? a.subagent_type ?? null,
            ok,
          });
        }
      } catch (err) {
        log({ type: "plugin_error", hook: "tool.execute.before", message: String(err).slice(0, 500) });
      }
    },

    // Idle marker: session finished a turn
    "session.idle": async (input) => {
      try {
        log({
          type: "session_idle",
          sessionID: input?.sessionID ?? null,
          turn: input?.turn ?? null,
        });
      } catch (err) {
        log({ type: "plugin_error", hook: "session.idle", message: String(err).slice(0, 500) });
      }
    },
  };
}