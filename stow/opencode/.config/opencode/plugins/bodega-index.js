/**
 * bodega-index v3 — Hook de config que registra skills/agents/commands en OpenCode.
 *
 * ## Ciclo de vida
 *
 * 1. OpenCode lee opencode.json → lista plugins → ejecuta hooks.config[]
 * 2. bodega-index.js lee los JSON manifests de ~/.config/opencode/plugins/
 * 3. Dedup por nombre: core (global) primero, bodega (ondemand) despues.
 * 4. Dedup por realpath: si dos paths resuelven al mismo directorio, uno solo.
 * 5. Skills: paths directos a config.skills.paths (schema valido)
 * 6. Agents: lee frontmatter de .md → config.agent[name] = AgentConfig
 * 7. Commands: lee frontmatter de .md → config.command[name] = { template, description }
 *
 * ## Manifests
 *
 *   bodega-global-skills.json     -> Core: skills siempre disponibles (paths)
 *   bodega-ondemand-skills.json   -> Bodega: skills descubribles (paths)
 *   bodega-global-agents.json     -> Core: agents siempre disponibles (paths)
 *   bodega-ondemand-agents.json   -> Bodega: agents descubribles (paths)
 *   bodega-global-commands.json   -> Core: commands siempre disponibles (paths)
 *   bodega-ondemand-commands.json -> Bodega: commands descubribles (paths)
 *
 * ## Troubleshooting
 *
 * - Una skill no aparece? Regenera manifests: python3 ~/.config/opencode/plugins/regenerate-manifests.py
 * - Path roto? Borra el repo de ~/tools/ y regenera.
 * - Debug: corre OpenCode con OPENCODE_DEBUG=1 para ver stderr del plugin.
 */

import path from "path";
import fs from "fs";

const PLUGINS = "/home/reeinharrrd/.config/opencode/plugins";

function readManifest(name) {
  try {
    return JSON.parse(fs.readFileSync(path.join(PLUGINS, name), "utf8"));
  } catch (e) {
    console.warn(`[bodega-index] manifest ${name} no cargado:`, e.message);
    return [];
  }
}

function dedupRealpath(paths, label) {
  const seen = new Set();
  const out = [];
  for (const p of paths) {
    let real;
    try {
      real = fs.realpathSync(p);
    } catch {
      real = p;
    }
    if (!seen.has(real)) {
      seen.add(real);
      out.push(p);
    } else {
      console.warn(`[bodega-index] ${label}: dedup realpath -> saltando ${p} (ya en ${real})`);
    }
  }
  return out;
}

function dedupByName(paths) {
  const seen = new Map();
  const out = [];
  const conflicts = [];

  for (const p of paths) {
    const name = path.basename(p);
    if (!seen.has(name)) {
      seen.set(name, p);
      out.push(p);
    } else {
      const prev = seen.get(name);
      if (prev !== p) {
        conflicts.push({ name, kept: prev, skipped: p });
      }
    }
  }

  if (conflicts.length > 0) {
    console.warn("[bodega-index] Conflictos de nombre (global gana):");
    for (const c of conflicts) {
      console.warn(`  "${c.name}" -> se queda: ${c.kept}`);
      console.warn(`               saltado: ${c.skipped}`);
    }
  }

  return out;
}

function skillNames(paths) {
  const names = new Set();
  for (const root of paths) {
    try {
      for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
        if (entry.isDirectory() && fs.existsSync(path.join(root, entry.name, "SKILL.md"))) {
          names.add(entry.name);
        }
      }
    } catch {}
  }
  return names;
}

/**
 * Extrae frontmatter YAML de un archivo .md.
 * Retorna un objeto plano con key: value.
 */
function extractFrontmatter(filePath) {
  try {
    const content = fs.readFileSync(filePath, "utf8");
    const match = content.match(/^---\n([\s\S]*?)\n---/);
    if (!match) return {};
    const frontmatter = {};
    for (const line of match[1].split("\n")) {
      const sep = line.indexOf(": ");
      if (sep > 0) {
        const key = line.slice(0, sep).trim();
        const val = line.slice(sep + 2).trim();
        frontmatter[key] = val;
      }
    }
    return frontmatter;
  } catch {
    return {};
  }
}

export default async function (ctx) {
  return {
    hooks: {
      config: [
        async (config) => {
          const globalSkills    = readManifest("bodega-global-skills.json");
          const ondemandSkills  = readManifest("bodega-ondemand-skills.json");
          const globalAgents    = readManifest("bodega-global-agents.json");
          const ondemandAgents  = readManifest("bodega-ondemand-agents.json");
          const globalCmds      = readManifest("bodega-global-commands.json");
          const ondemandCmds    = readManifest("bodega-ondemand-commands.json");

          // ── Skills ──────────────────────────────────────────
          // config.skills.paths is valid per OpenCode schema
          const combinedSkills = dedupByName([
            ...dedupRealpath(globalSkills, "skills"),
            ...dedupRealpath(ondemandSkills, "skills"),
          ]);

          config.skills = config.skills || {};
          config.skills.paths = config.skills.paths || [];
          const existingSkillNames = skillNames([
            ...config.skills.paths,
            path.join(process.env.HOME || "", ".config", "opencode", "skills"),
          ]);
          for (const p of combinedSkills) {
            try {
              if (fs.existsSync(p) && !existingSkillNames.has(path.basename(p)) && !config.skills.paths.includes(p))
                config.skills.paths.push(p);
            } catch {}
          }

          // ── Agents ──────────────────────────────────────────
          // OpenCode schema: config.agent[name] = AgentConfig
          // Not config.agents.paths — that key doesn't exist.
          const agentPaths = dedupByName([
            ...dedupRealpath(globalAgents, "agents"),
            ...dedupRealpath(ondemandAgents, "agents"),
          ]);

          config.agent = config.agent || {};
          for (const p of agentPaths) {
            try {
              const name = path.basename(p, ".md");
              if (config.agent[name]) continue; // preserve inline-defined overrides
              const fm = extractFrontmatter(p);
              const agentConfig = {};
              if (fm.description) agentConfig.description = fm.description;
              if (fm.mode) agentConfig.mode = fm.mode;
              const steps = parseInt(fm.steps, 10);
              if (!isNaN(steps)) agentConfig.steps = steps;
              config.agent[name] = agentConfig;
            } catch {}
          }

          // ── Commands ────────────────────────────────────────
          // OpenCode schema: config.command[name] = { template, description }
          const cmdPaths = dedupByName([
            ...dedupRealpath(globalCmds, "commands"),
            ...dedupRealpath(ondemandCmds, "commands"),
          ]);

          config.command = config.command || {};
          for (const p of cmdPaths) {
            try {
              const name = path.basename(p, ".md");
              if (config.command[name]) continue;
              const fm = extractFrontmatter(p);
              const cmdConfig = { template: name };
              if (fm.description) cmdConfig.description = fm.description;
              if (fm["argument-hint"]) cmdConfig.argumentHint = fm["argument-hint"];
              config.command[name] = cmdConfig;
            } catch {}
          }

          const numSkills = config.skills.paths ? config.skills.paths.length : 0;
          const numAgents = Object.keys(config.agent || {}).length;
          const numCommands = Object.keys(config.command || {}).length;
          console.log(`[bodega-index] loaded ${numSkills + numAgents + numCommands} total (skills: ${numSkills}, agents: ${numAgents}, commands: ${numCommands})`);

          return config;
        },
      ],
    },
  };
}
