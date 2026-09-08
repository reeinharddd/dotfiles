---
name: skill-router
description: >
  Lazy router for domain skills. Use this when you need a skill outside the core 7 — it
  will tell you whether to invoke `skill(name=...)` directly, check the project context,
  or invoke `capability-scanner` to discover unregistered capabilities.
  Trigger: "I need a skill for X", "which skill does Y", "load <name>", "find tool for Z".
---

# Skill Router — Lazy Loader

> **Este es el ÚNICO skill core sobre skills**. NO enumera skills específicas.
> Las skills específicas viven en `~/.config/opencode/domain-registry/REGISTRY.md` (lazy).

## Cuándo invocarme

- El usuario pide una funcionalidad y necesitas saber qué skill cargar
- Una tarea matchea un trigger pero no estás seguro si la skill existe
- Quieres cargar una skill específica por nombre
- No encuentras la skill en ningún registro conocido

## Flujo de decisión

### 1. ¿Es una skill core?

Las 5 skills core están **siempre inyectadas**. Si la tarea matchea:

| Tarea | Skill core |
|-------|------------|
| Tarea | Skill core |
|-------|------------|
| Session start, principios de comportamiento | `core-constitution` |
| Session start, info del sistema | `system-context` |
| Detección de proyecto/stack | `project-auto-detect` |
| Buscar skill/MCP no registrado | `capability-scanner` |
| Enrutar a skill de dominio/proyecto | `skill-router` |

→ **No me invoques a mí**, invoca la skill directamente.

### 2. ¿Es una skill del proyecto actual?

→ Lee `<project-root>/.opencode/PROJECT_CONTEXT.md` (sección "Project Skills")
→ Si está ahí → invoca `skill(name="<skill>")` directamente

### 3. ¿Es una skill de dominio pero no del proyecto?

→ Lee `~/.config/opencode/REGISTRY.md`
→ Busca por trigger en la tabla
→ Si matchea → invoca `skill(name="<skill>")`

### 4. ¿No encontraste nada en registry ni project?

→ **Invoca `capability-scanner`** para descubrir capabilities no registradas
→ Ejecuta `~/.config/opencode/scripts/capability-scanner.sh $PWD`
→ El scanner devuelve skills/MCPs que existen en el sistema pero no están registrados
→ Si está → invoca `skill(name="...")` o habilita MCP

### 5. ¿Sigue sin haber match?

→ **Pregúntale a reeinharrrd** qué skill aplicar
→ O sugiere crear nueva skill con `skill-creator`
→ O busca en npm con `npm search <keywords>`

## Regla de oro

**Nunca invoques skills que no existen.** Cada `skill(name=...)` inválido causa error.
Antes de cargar, verifica que está en core, registry, project, o discovered.

## Anti-patrones

❌ Cargar `react-expert` "por si acaso" en un proyecto Go
❌ Inyectar `geo-*` skills en trabajo que no es SEO
❌ Asumir que una skill existe sin verificar
❌ Decir "no encuentro skill" sin antes ejecutar `capability-scanner`

## Output esperado

Cuando me invoques, responde con:
1. ¿Core, proyecto, dominio, o descubierto?
2. Nombre exacto de la skill a cargar
3. Comando: `skill(name="<skill>")`

Si no hay match → sugiere `capability-scanner` o pide clarificación.