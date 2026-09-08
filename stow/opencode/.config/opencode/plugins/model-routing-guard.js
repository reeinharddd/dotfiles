/** guard v10 - purge non-free/non-accessible models; everything free/proven (pixtral vision, zen free, gemini, mistral). */
const CASCADE = {
  "build": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/mistral-medium-latest"],
  },
  "code-reviewer": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "opencode-zen/nemotron-3-ultra-free", "mistral/codestral-2508", "google/gemini-3.7-flash"],
  },
  "consult": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/mistral-medium-latest"],
  },
  "docs-lookup": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/mistral-medium-latest"],
  },
  "explore": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/ministral-8b-latest", "google/gemini-2.5-flash-lite"],
  },
  "fast": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/ministral-8b-latest", "google/gemini-2.5-flash-lite"],
  },
  "general": {
    mode: "all",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/mistral-medium-latest"],
  },
  "librarian": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/mistral-medium-latest"],
  },
  "metis": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/mistral-medium-latest"],
  },
  "momus": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/mistral-medium-latest"],
  },
  "multimodal-looker": {
    mode: "primary",
    model: "mistral/pixtral-12b-latest",
    fallback_models: ["mistral/mistral-medium-latest", "google/gemini-3.7-flash"],
  },
  "oracle": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/mistral-medium-latest"],
  },
  "plan": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/mistral-medium-latest"],
  },
  "plan-critic": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/mistral-medium-latest"],
  },
  "qa-enforcer": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/mistral-medium-latest"],
  },
  "scout": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/ministral-8b-latest", "google/gemini-2.5-flash-lite"],
  },
  "security-reviewer": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/mistral-medium-latest"],
  },
  "senior-researcher": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/mistral-medium-latest"],
  },
  "sisyphus-junior": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/ministral-8b-latest", "google/gemini-2.5-flash-lite"],
  },
  "smart": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/mistral-medium-latest"],
  },
  "subagent-orchestrator": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/mistral-medium-latest"],
  },
  "tdd-guide": {
    mode: "primary",
    model: "opencode-zen/nemotron-3-ultra-free",
    fallback_models: ["opencode-zen/mimo-v2.5-free", "google/gemini-3.7-flash", "mistral/mistral-medium-latest"],
  },
  "vision": {
    mode: "primary",
    model: "mistral/pixtral-12b-latest",
    fallback_models: ["mistral/mistral-medium-latest", "google/gemini-3.7-flash"],
  },
};
export default async function modelRoutingGuard(){return{config:async(c)=>{c.agent=c.agent||{};for(const[n,s]of Object.entries(CASCADE))c.agent[n]={...(c.agent[n]||{}),mode:s.mode,model:s.model,fallback_models:s.fallback_models}}};}
