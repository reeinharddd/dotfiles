# Bodega — Plugin System Architecture

Este directorio contiene el sistema de plugins de OpenCode para reeinharrrd,
que descubre skills, agents y commands desde `~/tools/` (la "bodega") y los
expone a OpenCode mediante manifests explícitos.

## Arquitectura

```
~/.config/opencode/plugins/
├── bodega-index.js                  ← Hook de config: carga manifests y registra paths
├── regenerate-manifests.py          ← Scanner: regenera los 5 manifests desde ~/tools/
├── bodega-global-skills.json         ← Core: skills siempre disponibles (291)
├── bodega-ondemand-skills.json       ← Bodega: skills descubribles por proyecto (970)
├── bodega-global-agents.json         ← Core: agents siempre disponibles (64)
├── bodega-ondemand-agents.json       ← Bodega: agents descubribles por proyecto (310)
├── bodega-ondemand-commands.json     ← Bodega: commands descubribles (21)
└── ... (otros plugins: ecc, superpowers, engram, etc.)
```

### Flujo de inicio

1. OpenCode carga `opencode.json` → lista plugins
2. Cada plugin exporta `hooks.config[]` — funciones que modifican el config final
3. `bodega-index.js` lee los 5 JSON manifests
4. Clasifica: **core** → `config.skills.paths[]` + `config.agents.paths[]` (siempre disponibles)
5. **Bodega** → también se agregan a paths (aparecen en `<available_skills>` pero no se cargan en contexto hasta que se invocan)
6. **Dedup**: si skills/agents tienen el mismo nombre, **core gana** (ECC/skills/ sobre .kiro/skills/, etc.)

### Core vs Bodega

| Categoría | Contenido | Carga |
|---|---|---|
| **Core** (global) | ECC English skills/agents, ~/tools/skills/ | Siempre en startup |
| **Bodega** (ondemand) | Skills ocultas, otros repos, locale copies, commands | Descubrible por proyecto, no en contexto |

## Manifests

### Formato

Cada manifest es un JSON array de strings (paths absolutos):

```json
[
  "/home/reeinharrrd/tools/ECC/skills/api-design",
  "/home/reeinharrrd/tools/skills/debugging",
  ...
]
```

### Clasificacion (regenerate-manifests.py)

`is_core_skill()` y `is_core_agent()` determinan si un item va a core o bodega:

- **Core skill**: path contiene `/ECC/skills/` y NO tiene `/docs/` (locale copies)
- **Core agent**: path contiene `/ECC/agents/` y NO tiene `/docs/`
- **Core skill adicional**: ~/tools/skills/* (fundamentos)
- **Commands**: siempre a bodega

## Scanner (regenerate-manifests.py)

### Que escanea

Todos los directorios dentro de `~/tools/` (cada repo clonado). Ademas:

- Sub-dirs especificos de plugins (engram/skills/, caveman/plugins/, etc.)
- **Directorios ocultos permitidos**: `.claude`, `.opencode`, `.codex`, `.kiro`, `.cursor`, `.windsurf`, `.github`
- Directorios SKIP: `.git`, `node_modules`, `.venv`, `__pycache__`, `.bun`, `dist`, `build`, `target`, `.angular`

### Que encuentra

- **Skills**: directorios que contienen `SKILL.md`
- **Agents**: archivos `.md` dentro de directorios llamados `agents`
- **Commands**: directorios llamados `commands` que contienen `.md`

### Uso

```bash
python3 ~/.config/opencode/plugins/regenerate-manifests.py
```

Idempotente. Se puede correr cuantas veces sea necesario.
Los manifests se sobrescriben completamente cada vez.

## bodega-index.js — Logica de dedup

```javascript
const combinedSkills = dedupByName([
    ...dedupRealpath(globalSkills, "skills"),   # core primero
    ...dedupRealpath(ondemandSkills, "skills"),  # bodega despues
]);
```

**Dedup por nombre** (basename del path): si dos skills tienen el mismo
nombre (ej: `ECC/skills/react-patterns` y `.kiro/skills/react-patterns`),
core gana. El conflicto se loggea a stderr.

**Dedup por realpath**: si dos paths resuelven al mismo directorio
via symlinks, solo se incluye uno.

## Problemas comunes

### 1. Una skill no aparece en `<available_skills>`

Causas posibles:
- El path no esta en ningun manifest → regenerar manifests
- El path esta en bodega pero el nombre colisiona con core → core gana por dedup
- El path existe pero no tiene SKILL.md → verificar estructura
- Symlink roto → realpath falla, se salta

### 2. Duplicados en `<available_skills>`

Si ves la misma skill dos veces, es porque:
- Dos paths distintos con el mismo nombre (uno core, otro bodega) → dedupByName
  los maneja, pero si el nombre difiere (ej: `career-ops` y `career-ops-v2`)
  aparecen ambos. Esto es intencional — se distinguen por nombre.
- Symlink a un dir que ya existe como path real → dedupRealpath lo maneja.

### 3. Path roto en manifest (ya no existe en disco)

Al regenerar manifests con `regenerate-manifests.py`, los paths que ya
no existen en disco se eliminan automaticamente. No hay limpieza manual.

### 4. Skills en `.claude/`, `.opencode/`, `.kiro/`, `.cursor/`

Estos directorios ocultos se escanean. Sus skills van a **bodega**,
no a core. Si hay colision de nombre con ECC/skills/, gana ECC.

### 5. regenerate-manifests.py falla

Errores comunes:
- `Permission denied` en algun directorio → se salta (try/except)
- `JSONDecodeError` en manifest existente → se trata como lista vacia
- Path muy largo (>4096) → error de OS, se salta

## Mantenimiento

### Agregar un repo nuevo a ~/tools/

```bash
git clone <repo> ~/tools/<repo>
python3 ~/.config/opencode/plugins/regenerate-manifests.py
```

### Remover un repo

```bash
rm -rf ~/tools/<repo>
python3 ~/.config/opencode/plugins/regenerate-manifests.py
```

### Verificar que todo funciona

```bash
python3 -c "
import json, os
for f in ['bodega-global-skills.json','bodega-ondemand-skills.json',
          'bodega-global-agents.json','bodega-ondemand-agents.json',
          'bodega-ondemand-commands.json']:
    data = json.load(open(os.path.join('/home/reeinharrrd/.config/opencode/plugins', f)))
    missing = [p for p in data if not os.path.exists(p)]
    print(f'{f}: {len(data)} entries, {len(missing)} missing')
    for p in missing:
        print(f'  MISSING: {p}')
"
```

### Debug de dedup

Revisar stderr de OpenCode al iniciar:

```
[bodega-index] Conflictos de nombre (global gana):
  "react-patterns" → se queda: /home/.../ECC/skills/react-patterns
               saltado: /home/.../ECC/.kiro/skills/react-patterns
```

Si ves un conflicto donde no deberia, cambia el orden en `dedupByName()`
en `bodega-index.js`, o ajusta la clasificacion en `regenerate-manifests.py`.

## Referencia

| Archivo | Rol |
|---|---|
| `bodega-index.js` | Plugin hook: carga manifests, dedup, registra paths |
| `regenerate-manifests.py` | Scanner: escanea ~/tools/ y regenera manifests |
| `bodega-*-*.json` | Manifests de skills/agents/commands |
| `.atl/` | Cache del skill-registry (auto-generado, no tocar) |
