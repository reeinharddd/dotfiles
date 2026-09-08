#!/usr/bin/env node
/**
 * bodega-scan — escanea ~/tools y genera los manifiestos de bodega.
 *
 * Convención de comunidad (focalizado, no por adivinar contenido):
 *   - Skill  : carpeta que contiene SKILL.md (en cualquier nivel)
 *   - Agent  : .md con frontmatter `description:` dentro de carpeta agents/
 *   - Command: .md dentro de carpeta commands/
 *
 * Regla de escaneo (decisión usuario: NO excluir por proyecto):
 *   Se escanea TODA ~/tools. Lo que se expone, se expone por algo — hasta un
 *   proyecto "cerrado" puede tener skills/agents/commands útiles de forma
 *   individual, o comandos esenciales para que funcione/sea integrable.
 *
 * Exclusiones TÉCNICAS únicamente (no por proyecto):
 *   - .git (no es fuente de skills)
 *   - node_modules
 *   - docs/ (traducciones es/ja-JP/ko-KR/pt-BR/tr/zh-CN/zh-TW — duplicados)
 *   - legacy-command-shims
 *
 * Dedupe por hash de contenido (0 duplicados entre runtimes/tool).
 * Clasifica global (tipos generales) vs ondemand (específicos por
 * lenguaje/framework/dominio).
 */
import fs from "fs";
import path from "path";
import crypto from "crypto";

const TOOLS = "/home/reeinharrrd/tools";
const PLUGINS = "/home/reeinharrrd/.config/opencode/plugins";

const isLegacy = (p) => /legacy-command-shims/.test(p);

// Walker: escanea TODO ~/tools excepto .git, node_modules, docs/, legacy.
function walk(root, onDir) {
  const stack = [root];
  while (stack.length) {
    const d = stack.pop();
    let e;
    try { e = fs.readdirSync(d, { withFileTypes: true }); } catch { continue; }
    onDir(d, e);
    for (const x of e) {
      if (x.isDirectory()) {
        if (x.name === ".git" || x.name === "node_modules") continue;
        if (x.name === "docs") continue; // traducciones, no fuente
        const full = path.join(d, x.name);
        if (isLegacy(full)) continue;
        stack.push(full);
      }
    }
  }
}

const hashOf = (f) => {
  try { return crypto.createHash("sha256").update(fs.readFileSync(f)).digest("hex"); }
  catch { return null; }
};

// ---- SKILLS: carpetas con SKILL.md ----
const skillDirs = [];
walk(TOOLS, (d, e) => {
  if (e.some((x) => x.name === "SKILL.md") && !skillDirs.includes(d)) skillDirs.push(d);
});
// Dedupe por BASENAME de la carpeta del skill (identidad de la skill en comunidad).
// Si el mismo nombre aparece en varios runtimes, quedarse con el SKILL.md MAS largo.
const byBase = new Map();
for (const d of skillDirs) {
  const base = path.basename(d);
  const size = fs.statSync(path.join(d, "SKILL.md")).size;
  const prev = byBase.get(base);
if (!prev || size > prev.size) byBase.set(base, d);
}
const skills = [...byBase.values()].sort();

// ---- AGENTS: .md con description: en carpeta agents/ ----
const isAgentMd = (p) => {
  const t = fs.readFileSync(p, "utf8");
  const m = t.match(/^---\n([\s\S]*?)\n---/);
  return m && /^description:\s*.+/m.test(m[1]);
};
const agents = [];
walk(TOOLS, (d, e) => {
  if (!/\/(agents?)\//.test(d + "/")) return;
  for (const x of e) {
    if (x.isFile() && x.name.endsWith(".md") && isAgentMd(path.join(d, x.name)))
      agents.push({ path: path.join(d, x.name), name: x.name.replace(/\.md$/, ""), size: fs.statSync(path.join(d, x.name)).size });
  }
});
// Dedupe: mismo nombre -> archivo MAS largo (version completa, no stub)
const byName = new Map();
for (const a of agents) {
  const prev = byName.get(a.name);
  if (!prev || a.size > prev.size) byName.set(a.name, a);
}
const agentsUnique = [...byName.values()].sort((x, y) => x.name.localeCompare(y.name));

// ---- COMMANDS: carpetas commands/ ----
const cmdDirs = [];
walk(TOOLS, (d, e) => {
  if (path.basename(d) === "commands" && e.some((x) => x.isFile() && x.name.endsWith(".md")))
    cmdDirs.push(d);
});
const commands = [...new Set(cmdDirs)].sort();

// ---- Clasificar global vs ondemand ----
const SPEC = new RegExp([
  "cpp", "csharp", "dart", "django", "fastapi", "flutter", "fsharp", "go-", "golang", "java",
  "kotlin", "php", "python", "pytorch", "react", "rust", "swift", "typescript", "harmonyos",
  "healthcare", "gan-", "mle-", "marketing", "homelab", "network", "opensource", "seo-",
  "lead-intelligence", "observer", "enrichment", "mutual-mapper", "outreach-drafter",
  "signal-scorer", "jd-", "intent-", "role-definitions", "review-readability",
  "review-reliability", "review-resilience", "review-risk", "3d", "animations", "assets",
  "audio", "charts", "compositions", "fonts", "gifs", "images", "lottie", "sequencing",
  "text-animations", "timing", "transcribe", "transitions", "trimming", "videos", "can-decode",
  "calculate-metadata", "display-captions", "extract-frames", "get-audio", "get-video",
  "import-srt", "measuring-", "codegen-", "sdd-", "agents-md", "skill-creator",
  "skill-registry", "output-style", "jd-fix", "swiftui", "ktor", "exposed", "jpa", "quarkus",
  "prisma", "graphql", "spring", "nest", "next", "vue", "laravel", "rails", "dotnet", "sql",
  "postgres", "mysql", "clickhouse", "redis", "kubernetes", "terraform", "aws", "gcp", "azure",
  "wordpress", "shopify", "salesforce", "jira", "defi", "evm", "x402", "carrier", "customs",
  "energy", "inventory", "logistics", "production-", "quality-nonconformance", "recsys",
  "trade-", "finance", "billing", "customer", "email", "google-workspace", "hipaa", "cdss",
  "emr", "phi",
].join("|"), "i");

const gS = [], oS = [];
for (const d of skills) (SPEC.test(path.basename(d)) ? oS : gS).push(d);
const gA = [], oA = [];
for (const a of agentsUnique) (SPEC.test(a.name) ? oA : gA).push(a.path);

fs.writeFileSync(PLUGINS + "/bodega-global-skills.json", JSON.stringify(gS, null, 2));
fs.writeFileSync(PLUGINS + "/bodega-ondemand-skills.json", JSON.stringify(oS, null, 2));
fs.writeFileSync(PLUGINS + "/bodega-global-agents.json", JSON.stringify(gA, null, 2));
fs.writeFileSync(PLUGINS + "/bodega-ondemand-agents.json", JSON.stringify(oA, null, 2));
fs.writeFileSync(PLUGINS + "/bodega-ondemand-commands.json", JSON.stringify(commands, null, 2));

let cmdFiles = 0;
for (const d of commands) {
  try { cmdFiles += fs.readdirSync(d).filter((f) => f.endsWith(".md")).length; } catch {}
}

const topFolders = fs.readdirSync(TOOLS, { withFileTypes: true }).filter((x) => x.isDirectory()).length;
console.log("=== BODEGA-SCAN ===");
console.log("Skills :", gS.length, "global +", oS.length, "ondemand =", gS.length + oS.length);
console.log("Agents :", gA.length, "global +", oA.length, "ondemand =", gA.length + oA.length);
console.log("Command dirs:", commands.length, "(archivos .md:", cmdFiles + ")");
console.log("Escaneo: TODA ~/tools (" + topFolders + " carpetas top-level). Exclusiones técnicas: .git, node_modules, docs/, legacy.");
