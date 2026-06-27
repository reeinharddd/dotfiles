import type { Plugin } from "@opencode-ai/plugin"
import { Database } from "bun:sqlite"

const DATA_DIR = process.env.OPENDATA_DIR || process.env.HOME + "/.local/share/opencode"
const DB_PATH = DATA_DIR + "/ctx-analyze.db"

const SCHEMA = `
CREATE TABLE IF NOT EXISTS system_prompt (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hash TEXT NOT NULL,
    parts TEXT NOT NULL,
    full_text TEXT NOT NULL,
    tokens_estimated INTEGER,
    session_id TEXT,
    model TEXT,
    time_captured INTEGER
);
CREATE INDEX IF NOT EXISTS idx_sysp_hash ON system_prompt(hash);
CREATE INDEX IF NOT EXISTS idx_sysp_sess ON system_prompt(session_id);

CREATE TABLE IF NOT EXISTS switch_event (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    type TEXT NOT NULL,
    from_value TEXT,
    to_value TEXT,
    message_id TEXT,
    time_created INTEGER
);
CREATE INDEX IF NOT EXISTS idx_sw_sess ON switch_event(session_id);

CREATE TABLE IF NOT EXISTS compaction_event (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT,
    tokens_before INTEGER,
    tokens_after INTEGER,
    summary TEXT,
    time_created INTEGER
);
CREATE INDEX IF NOT EXISTS idx_comp_sess ON compaction_event(session_id);

CREATE TABLE IF NOT EXISTS tracked_session (
    id TEXT PRIMARY KEY,
    title TEXT,
    model TEXT,
    agent TEXT,
    msg_count INTEGER DEFAULT 0,
    time_created INTEGER,
    time_updated INTEGER
);

CREATE TABLE IF NOT EXISTS breakdown (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    message_seq INTEGER,
    component TEXT NOT NULL,
    tokens_estimated INTEGER,
    label TEXT,
    detail_json TEXT,
    time_created INTEGER
);
CREATE INDEX IF NOT EXISTS idx_brk_sess ON breakdown(session_id);

CREATE TABLE IF NOT EXISTS context_snapshot (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    system_prompt_hash TEXT,
    num_context_messages INTEGER,
    total_estimated_tokens INTEGER,
    user_message_hash TEXT,
    user_message_preview TEXT,
    model TEXT,
    time_created INTEGER
);
CREATE INDEX IF NOT EXISTS idx_cs_sess ON context_snapshot(session_id);
`

function sha256hex(s: string): string {
  const hash = new Bun.CryptoHasher("sha256")
  hash.update(s)
  return hash.digest("hex")
}

function estTokens(s: string): number {
  return Math.round(s.length / 4)
}

interface TokenCache {
  input: number;
  output: number;
  cache_read: number;
  cache_write: number;
}

const tokenCache = new Map<string, TokenCache>()

const P: Plugin = async () => {
  const db = new Database(DB_PATH, { create: true })
  db.exec(SCHEMA)

  const insSysp = db.prepare(
    `INSERT INTO system_prompt (hash, parts, full_text, tokens_estimated, session_id, model, time_captured)
     VALUES ($hash, $parts, $full_text, $tokens_estimated, $session_id, $model, $time_captured)`
  )

  const insSwitch = db.prepare(
    `INSERT INTO switch_event (session_id, type, from_value, to_value, message_id, time_created)
     VALUES ($session_id, $type, $from, $to, $message_id, $time_created)`
  )

  const insCompaction = db.prepare(
    `INSERT INTO compaction_event (session_id, tokens_before, tokens_after, summary, time_created)
     VALUES ($session_id, $tokens_before, $tokens_after, $summary, $time_created)`
  )

  const insBreakdown = db.prepare(
    `INSERT INTO breakdown (session_id, message_seq, component, tokens_estimated, label, detail_json, time_created)
     VALUES ($session_id, $message_seq, $component, $tokens_estimated, $label, $detail_json, $time_created)`
  )

  const insSnapshot = db.prepare(
    `INSERT INTO context_snapshot
     (session_id, system_prompt_hash, num_context_messages, total_estimated_tokens, user_message_hash, user_message_preview, model, time_created)
     VALUES ($session_id, $sysp_hash, $num_msgs, $est_tokens, $user_hash, $user_preview, $model, $time)`
  )

  const getSyspByHash = db.prepare(
    "SELECT id FROM system_prompt WHERE hash = $hash AND session_id = $session_id"
  )

  return {
    async dispose() {
      db.close()
    },

    hooks: {
      "experimental.chat.system.transform": async (input, output) => {
        const system = output.system
        if (!system || system.length === 0) return

        const fullText = system.join("\n")
        const hash = sha256hex(fullText)
        const now = Date.now()

        const exists = getSyspByHash.get({ hash, session_id: input.sessionID })
        if (!exists) {
          insSysp.run({
            hash,
            parts: JSON.stringify(system),
            full_text: fullText,
            tokens_estimated: estTokens(fullText),
            session_id: input.sessionID,
            model: input.model?.modelID,
            time_captured: now,
          })

          // Update tracked_session
          db.run(
            "INSERT INTO tracked_session (id, model, time_created, time_updated) VALUES ($id, $model, $now, $now) ON CONFLICT(id) DO UPDATE SET model=$model, time_updated=$now",
            { id: input.sessionID, model: input.model?.modelID, now }
          )
        }
      },

      event: async ({ event }) => {
        if (event.type === "session.created.1") {
          const now = Date.now()
          tokenCache.set(event.sessionID, { input: 0, output: 0, cache_read: 0, cache_write: 0 })
          db.run(
            "INSERT INTO tracked_session (id, time_created, time_updated) VALUES ($id, $now, $now) ON CONFLICT(id) DO UPDATE SET time_updated=$now",
            { id: event.sessionID, now }
          )
        }

        if (event.type === "session.next.model.switched.1") {
          let data: Record<string, unknown> = {}
          try { data = JSON.parse(event.data || "{}") } catch { /* ignore */ }
          insSwitch.run({
            session_id: event.sessionID,
            type: "model",
            from: String(data.from ?? ""),
            to: String(data.to ?? ""),
            message_id: event.messageID,
            time_created: event.timeCreated,
          })
        }

        if (event.type === "session.next.agent.switched.1") {
          let data: Record<string, unknown> = {}
          try { data = JSON.parse(event.data || "{}") } catch { /* ignore */ }
          insSwitch.run({
            session_id: event.sessionID,
            type: "agent",
            from: String(data.from ?? ""),
            to: String(data.to ?? ""),
            message_id: event.messageID,
            time_created: event.timeCreated,
          })
        }
      },

      "experimental.session.compacting": async (input, output) => {
        const now = Date.now()
        const cached = tokenCache.get(input.sessionID)
        const before = cached?.input ?? null
        const summary = output.context ? output.context.join("\n") : ""
        tokenCache.set(input.sessionID, { input: 0, output: 0, cache_read: 0, cache_write: 0 })
        insCompaction.run({
          session_id: input.sessionID,
          tokens_before: before,
          tokens_after: 0,
          summary,
          time_created: now,
        })
      },

      "chat.message": async (input) => {
        const now = Date.now()
        db.run(
          "INSERT INTO tracked_session (id, model, agent, msg_count, time_created, time_updated) VALUES ($id, $model, $agent, 1, $now, $now) ON CONFLICT(id) DO UPDATE SET model=COALESCE($model,model), agent=COALESCE($agent,agent), msg_count=msg_count+1, time_updated=$now",
          { id: input.sessionID, model: input.model?.modelID, agent: input.agent, now }
        )

        const tc = tokenCache.get(input.sessionID) || { input: 0, output: 0, cache_read: 0, cache_write: 0 }
        const msgTokens = (input as any).tokens
        if (msgTokens) {
          tc.input += msgTokens.input || 0
          tc.output += msgTokens.output || 0
          tc.cache_read += msgTokens.cache_read || 0
          tc.cache_write += msgTokens.cache_write || 0
        }
        tokenCache.set(input.sessionID, tc)
      },

      "experimental.chat.messages.transform": async (_input, output) => {
        if (!output.messages || output.messages.length === 0) return
        const last = output.messages[output.messages.length - 1]
        if (!last || !last.info) return

        const sysPart = output.messages[0]
        let syspHash = "" as string | null
        if (sysPart && sysPart.info.role === "system") {
          const sysText = sysPart.parts
            .filter((p) => p.type === "text")
            .map((p) => (p as any).text || "")
            .join("\n")

          if (sysText) {
            const hash = sha256hex(sysText)
            syspHash = hash
            const exists = getSyspByHash.get({ hash, session_id: _input.sessionID })
            if (!exists && _input.sessionID) {
              insSysp.run({
                hash,
                parts: JSON.stringify(sysPart.parts.map((p) => (p as any).text || "")),
                full_text: sysText,
                tokens_estimated: estTokens(sysText),
                session_id: _input.sessionID,
                model: null,
                time_captured: Date.now(),
              })
            }
          }
        }

        // Capture context snapshot
        const userTexts = last.parts
          .filter((p) => p.type === "text")
          .map((p) => (p as any).text || "")
        const userFull = userTexts.join("\n")
        if (!userFull.trim() || !_input.sessionID) return

        let totalChars = 0
        for (const m of output.messages) {
          for (const p of m.parts) {
            if (p.type === "text") totalChars += ((p as any).text || "").length
          }
        }

        insSnapshot.run({
          session_id: _input.sessionID,
          sysp_hash: syspHash,
          num_msgs: output.messages.length,
          est_tokens: Math.round((totalChars || 1) / 4),
          user_hash: sha256hex(userFull),
          user_preview: userFull.slice(0, 200),
          model: null,
          time: Date.now(),
        })
      },
    },
  }
}

export default P
