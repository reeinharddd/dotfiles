/** guard v12 — free-only routing, audited live 2026-09-11.
 *  FIX CRÍTICO: NO inyectar `fallback_models` en config.agent de opencode.
 *  opencode 1.18.29 enruta campos desconocidos de agent → provider options → body API;
 *  NVIDIA responde 400 "Unsupported parameter(s): `fallback_models`" (validación estricta).
 *  Los fallbacks en cascada viven SOLO en oh-my-openagent.json (model_fallback runtime real).
 *  Aquí solo se fija el model primario por agent (fuente de verdad de routing). */
const CASCADE = {
  "build":            "opencode-zen/nemotron-3-ultra-free",
  "smart":            "opencode-zen/nemotron-3-ultra-free",
  "general":          "opencode-zen/nemotron-3-ultra-free",
  "plan":             "opencode-zen/nemotron-3-ultra-free",
  "oracle":           "nvidia/deepseek-ai/deepseek-v4-pro-0813",
  "tdd-guide":        "opencode-zen/nemotron-3-ultra-free",
  "qa-enforcer":      "opencode-zen/nemotron-3-ultra-free",
  "subagent-orchestrator": "opencode-zen/nemotron-3-ultra-free",
  "code-reviewer":    "opencode-zen/nemotron-3-ultra-free",
  "security-reviewer": "opencode-zen/nemotron-3-ultra-free",
  "metis":            "opencode-zen/nemotron-3-ultra-free",
  "momus":            "opencode-zen/nemotron-3-ultra-free",
  "consult":          "opencode-zen/nemotron-3-ultra-free",
  "plan-critic":      "opencode-zen/nemotron-3-ultra-free",
  "senior-researcher": "opencode-zen/nemotron-3-ultra-free",
  "fast":             "opencode-zen/nemotron-3.5-lightning-free",
  "sisyphus-junior":  "opencode-zen/nemotron-3.5-lightning-free",
  "explore":          "opencode-zen/nemotron-3.5-lightning-free",
  "scout":            "opencode-zen/nemotron-3.5-lightning-free",
  "docs-lookup":      "google/gemini-3.8-flash",
  "librarian":        "google/gemini-3.8-flash",
  "vision":           "opencode-zen/mimo-v2.5-free",
  "multimodal-looker": "opencode-zen/mimo-v2.5-free",
};
const MODE = { general: "all" };
export default async function modelRoutingGuard(){
  return { config: async (c) => {
    c.agent = c.agent || {};
    for (const [n, model] of Object.entries(CASCADE)) {
      c.agent[n] = { ...(c.agent[n] || {}), mode: MODE[n] ?? "primary", model };
    }
  }};
}
