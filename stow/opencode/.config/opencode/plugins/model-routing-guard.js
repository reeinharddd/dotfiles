/** guard v21 — Zen-free default por benchmark, free-only 2026-09-22.
 *  FIX CRÍTICO: NO inyectar `fallback_models` en config.agent de opencode.
 *  opencode 1.18.29 enruta campos desconocidos de agent → provider options → body API;
 *  NVIDIA responde 400 "Unsupported parameter(s): `fallback_models`" (validación estricta).
 *  Los fallbacks en cascada viven SOLO en oh-my-openagent.json + ~/.omo/omo.jsonc.
 *  v21 (2026-09-22): default Zen-free en TODOS los agentes por benchmarks:
 *  coding/planes/reviewers → mimo-v2.6-flash-free (SWE-Bench Thinking 78.6, TB2.1 87.6%);
 *  ejecución/subagentes → ling-3.0-flash-fin-free (347 tok/s, TTFT 1.6s);
 *  razonamiento → nemotron-3-ultra-free (SWE 71.9); rapidez → nemotron-3.5-lightning-free;
 *  visión → muse-spark-1.3-contributor-free (único Zen free multimodal).
 *  big-pickle/mimo-v2.5 solo como fallback (ya dieron 403 en subagentes).
 *  v14 (2026-09-17): general mode "all"→"primary" — mode=all hacía que el subagente
 *  general invocara zen free vía API path y fallara con AI_APICallError "free tier can
 *  only be used from within OpenCode". Todos los agentes quedan en primary.
 *  v15 (2026-09-18): mode=primary NO basta para delegaciones background — el worker
 *  background no lleva el contexto Console de la app y todo modelo zen-free falla con
 *  403 FreeTierError "OpenCode's free tier can only be used from within OpenCode"
 *  (el fallo se traga como "Delegation completed without text output.").
 *  v17-v18 (2026-09-18): ampliación no-zen a TODOS los agentes delegables/subagentes
 *  (metis, momus, sisyphus-junior, explore, scout, code-reviewer, security-reviewer,
 *  consult, plan-critic, senior-researcher, etc.) diversificando entre NVIDIA,
 *  Mistral, Google y OpenRouter para resiliencia total y fallbacks completos.
 *  v19 (2026-09-18): vision/multimodal-looker migran de opencode-zen/mimo-v2.5-free
 *  a google/gemini-3.8-flash (mimo: sin vision confiable + 403 FreeTier Console en
 *  subagentes — ver log 20:42 look_at). Zero zen en rutas visuales. */
const CASCADE = {
  "build":            "opencode-zen/mimo-v2.6-flash-free",
  "smart":            "opencode-zen/mimo-v2.6-flash-free",
  "general":          "opencode-zen/ling-3.0-flash-fin-free",
  "plan":             "opencode-zen/mimo-v2.6-flash-free",
  "oracle":           "opencode-zen/nemotron-3-ultra-free",
  "tdd-guide":        "opencode-zen/mimo-v2.6-flash-free",
  "qa-enforcer":      "opencode-zen/mimo-v2.6-flash-free",
  "subagent-orchestrator": "opencode-zen/ling-3.0-flash-fin-free",
  "code-reviewer":    "opencode-zen/mimo-v2.6-flash-free",
  "security-reviewer": "opencode-zen/mimo-v2.6-flash-free",
  "metis":            "opencode-zen/mimo-v2.6-flash-free",
  "momus":            "opencode-zen/mimo-v2.6-flash-free",
  "consult":          "opencode-zen/mimo-v2.6-flash-free",
  "plan-critic":      "opencode-zen/mimo-v2.6-flash-free",
  "senior-researcher": "opencode-zen/mimo-v2.6-flash-free",
  "fast":             "opencode-zen/nemotron-3.5-lightning-free",
  "sisyphus-junior":  "opencode-zen/ling-3.0-flash-fin-free",
  "explore":          "opencode-zen/ling-3.0-flash-fin-free",
  "scout":            "opencode-zen/ling-3.0-flash-fin-free",
  "docs-lookup":      "opencode-zen/ling-3.0-flash-fin-free",
  "librarian":        "opencode-zen/ling-3.0-flash-fin-free",
  "vision":           "opencode-zen/muse-spark-1.3-contributor-free",
  "multimodal-looker": "opencode-zen/muse-spark-1.3-contributor-free",
  "prometheus":       "opencode-zen/mimo-v2.6-flash-free",
  "atlas":            "opencode-zen/ling-3.0-flash-fin-free",
};
const MODE = {};
export default async function modelRoutingGuard(){
  return { config: async (c) => {
    c.agent = c.agent || {};
    for (const [n, model] of Object.entries(CASCADE)) {
      c.agent[n] = { ...(c.agent[n] || {}), mode: MODE[n] ?? "primary", model };
    }
  }};
}
