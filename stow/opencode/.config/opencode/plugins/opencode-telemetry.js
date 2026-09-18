/**
 * opencode-telemetry.js — event ledger for observability (v1, 2026-09-17)
 *
 * Records structured events to ~/.local/share/opencode/telemetry/events/YYYY-MM-DD.jsonl
 * so failures, delegations, and tool activity are debuggable after the fact.
 * Events: boot (plugin load), tool (tool.execute.before with result status),
 * delegation (delegate/task calls incl. run_in_background flag), session.idle.
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

function log(entry) {
  try {
    fs.mkdirSync(TELEMETRY_DIR, { recursive: true });
    const day = new Date().toISOString().slice(0, 10);
    const file = path.join(TELEMETRY_DIR, day + ".jsonl");
    fs.appendFileSync(file, JSON.stringify({ ts: new Date().toISOString(), ...entry }) + "\n");
  } catch {
    /* telemetry is best-effort, never break the flow */
  }
}

function summarizeArgs(input) {
  try {
    if (!input || typeof input !== "object") return {};
    const copy = { ...input };
    for (const [k, v] of Object.entries(copy)) {
      const s = typeof v === "string" ? v : JSON.stringify(v);
      copy[k] = s && s.length > 300 ? s.slice(0, 300) + "…" : v;
    }
    return copy;
  } catch {
    return {};
  }
}

export default async function opencodeTelemetry() {
  return {
    // Boot marker: fires when plugins are wired into config
    config: async (config) => {
      log({
        type: "boot",
        plugin: "opencode-telemetry",
        version: config?.version ?? "unknown",
        agentCount: config?.agent ? Object.keys(config.agent).length : undefined,
      });
    },

    // Tool execution ledger: name, args (truncated), and success/failure
    "tool.execute.before": async (input, output) => {
      try {
        if (!input || typeof input.tool !== "string") return;
        const ok = !output || !output.isError;
        const entry = {
          type: "tool",
          tool: input.tool,
          ok,
          args: summarizeArgs(input.input),
        };
        if (!ok && output?.error) entry.error = String(output.error).slice(0, 500);
        log(entry);

        // Delegation visibility: flag run_in_background for post-hoc debugging
        if (input.tool === "delegate" || input.tool === "task") {
          log({
            type: "delegation",
            tool: input.tool,
            background: Boolean(input.input?.run_in_background),
            agent: input.input?.agent ?? input.input?.subagent_type ?? null,
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