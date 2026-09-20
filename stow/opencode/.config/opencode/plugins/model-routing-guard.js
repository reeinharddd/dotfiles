/** guard v18 — free-only routing, audited live 2026-09-18.
 *  FIX CRÍTICO: NO inyectar `fallback_models` en config.agent de opencode.
 *  opencode 1.18.29 enruta campos desconocidos de agent → provider options → body API;
 *  NVIDIA responde 400 "Unsupported parameter(s): `fallback_models`" (validación estricta).
 *  Los fallbacks en cascada viven SOLO en oh-my-openagent.json (model_fallback runtime real).
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
  "build":            "opencode-zen/nemotron-3-ultra-free",
  "smart":            "opencode-zen/nemotron-3-ultra-free",
  "general":          "nvidia/deepseek-ai/deepseek-v4-flash-0731",
  "plan":             "nvidia/deepseek-ai/deepseek-v4-flash-0731",
  "oracle":           "nvidia/deepseek-ai/deepseek-v4-flash-0731",
  "tdd-guide":        "nvidia/deepseek-ai/deepseek-v4-flash-0731",
  "qa-enforcer":      "nvidia/deepseek-ai/deepseek-v4-flash-0731",
  "subagent-orchestrator": "nvidia/deepseek-ai/deepseek-v4-flash-0731",
  "code-reviewer":    "mistral/mistral-medium-latest",
  "security-reviewer": "mistral/mistral-medium-latest",
  "metis":            "mistral/mistral-medium-latest",
  "momus":            "mistral/mistral-medium-latest",
  "consult":          "nvidia/deepseek-ai/deepseek-v4-flash-0731",
  "plan-critic":      "mistral/mistral-medium-latest",
  "senior-researcher": "google/gemini-3.8-flash",
  "fast":             "google/gemini-3.5-flash-lite",
  "sisyphus-junior":  "nvidia/deepseek-ai/deepseek-v4-flash-0731",
  "explore":          "google/gemini-3.5-flash-lite",
  "scout":            "google/gemini-3.5-flash-lite",
  "docs-lookup":      "google/gemini-3.8-flash",
  "librarian":        "google/gemini-3.8-flash",
  "vision":           "google/gemini-3.8-flash",
  "multimodal-looker": "google/gemini-3.8-flash",
  "prometheus":       "nvidia/deepseek-ai/deepseek-v4-flash-0731",
  "atlas":            "nvidia/deepseek-ai/deepseek-v4-flash-0731",
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
