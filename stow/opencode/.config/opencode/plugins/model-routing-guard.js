/** model-routing-guard v22 — VALIDATE ONLY (OLA 05).
 *  OMO (oh-my-openagent.json) is the SOLE routing authority for agent → model + fallback chains.
 *  This plugin never decides routes and never injects config.agent models.
 *  It reads OMO from disk and rejects free=UNKNOWN / oversize chains against model-registry.free.yaml.
 *
 *  Policy:
 *    primary  → free:KNOWN only
 *    fallback → free:KNOWN | free:QUOTA, max 3, distinct providers when ≥2
 *    free:UNKNOWN → not routed
 *
 *  LiteLLM = provider failover only (not model selection). See opencode.jsonc litellm block.
 *
 *  v21 history: injected CASCADE (decided) — removed in v22 per one-authority rule.
 *  Do NOT inject fallback_models into config.agent (opencode 1.18.29 → 400 on provider API).
 */
import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

const MAX_FALLBACKS = 3;
const OMO_PATH = join(homedir(), ".config/opencode/oh-my-openagent.json");
const REGISTRY_PATH = join(homedir(), ".config/opencode/model-registry.free.yaml");

function loadRegistry() {
  if (!existsSync(REGISTRY_PATH)) return null;
  try {
    const text = readFileSync(REGISTRY_PATH, "utf8");
    const models = {};
    let inModels = false;
    for (const raw of text.split("\n")) {
      const line = raw.replace(/#.*$/, "").trimEnd();
      if (!line) continue;
      if (/^models:/.test(line)) {
        inModels = true;
        continue;
      }
      if (/^[a-z_]+:/.test(line) && !line.startsWith(" ")) {
        inModels = false;
        continue;
      }
      if (!inModels) continue;
      // Quoted keys first (model ids contain ':'), then bare keys without colon
      const m =
        line.match(/^\s+"([^"]+)":\s*\{\s*free:\s*(\w+)\s*\}/) ||
        line.match(/^\s+([^\s:]+):\s*\{\s*free:\s*(\w+)\s*\}/);
      if (m) models[m[1]] = m[2];
    }
    return Object.keys(models).length ? models : null;
  } catch {
    return null;
  }
}

function loadOmoAgents() {
  if (!existsSync(OMO_PATH)) return null;
  try {
    const j = JSON.parse(readFileSync(OMO_PATH, "utf8"));
    return j?.agents || null;
  } catch {
    return null;
  }
}

function providerOf(model) {
  return String(model || "").split("/")[0] || "";
}

function validateAgent(name, agent, registry) {
  const errors = [];
  const primary = agent?.model;
  if (registry) {
    const pStat = primary ? registry[primary] : undefined;
    if (!primary || pStat !== "KNOWN") {
      errors.push(`${name}: primary "${primary}" free=${pStat || "UNKNOWN"} → reject (need KNOWN)`);
    }
    const fbs = agent.fallback_models || [];
    for (const fb of fbs) {
      const st = registry[fb];
      if (st !== "KNOWN" && st !== "QUOTA") {
        errors.push(`${name}: fallback "${fb}" free=${st || "UNKNOWN"} → reject (need KNOWN|QUOTA)`);
      }
    }
  }
  const fbs = agent.fallback_models || [];
  if (fbs.length > MAX_FALLBACKS) {
    errors.push(`${name}: ${fbs.length} fallbacks > max ${MAX_FALLBACKS}`);
  }
  const providers = new Set(fbs.map(providerOf));
  if (fbs.length >= 2 && providers.size < Math.min(2, fbs.length)) {
    errors.push(`${name}: fallbacks must use distinct providers`);
  }
  return errors;
}

export default async function modelRoutingGuard() {
  return {
    config: async () => {
      const registry = loadRegistry();
      const agents = loadOmoAgents();
      if (!agents || !registry) {
        console.error(
          "[model-routing-guard] skip: missing OMO agents or free registry (cannot validate)",
        );
        return;
      }
      const all = [];
      for (const [name, agent] of Object.entries(agents)) {
        if (!agent || typeof agent !== "object") continue;
        if (!agent.model) continue;
        all.push(...validateAgent(name, agent, registry));
      }
      if (all.length) {
        const msg = `[model-routing-guard] free-only violations:\n${all.join("\n")}`;
        console.error(msg);
        throw new Error(msg);
      }
    },
  };
}
