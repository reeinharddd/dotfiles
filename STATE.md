# STATE.md — Estado vivo del sistema

> Actualizar al cerrar cada sesión de trabajo significativa.
> Par de entrada: STATE.md (qué está pasando) + WORKFLOW.md (cómo se trabaja).

# Estado

- Fecha: 2026-09-20
- Disco: 118G / 468G usados (27%, 327G libres)
- RAM: 13Gi total / ~8.6Gi en uso, zram zstd 6.9G activo
- Docker: 4 contenedores — wedo-db (:5433, healthy), qdrant (:6333),
  taskchampion-sync (:8090), mikedb (:5432, lab2 9°, detenido por diseño)
- Sesión opencode: múltiples activas (wedo + home) — NUNCA matar

## Proyecto activo

- **wedo** — gestión hogar (~/projects/personal/wedo), 5+ procesos opencode
- **dispositivos 9°** — ~/School/dispositivos (lab2 + labC), cuatrimestre en curso

## Pendientes

- [ ] Verificar provider zen de hermes tras fix (hermes -z debe responder)
- [ ] Correr `just doc` semanal (timer doc-refresh lo automatiza)
- [ ] Rotar contraseña sudo real (ejecutar `passwd`)
- [ ] Rotar Firecrawl API key real (dashboard)
- [ ] Guardar restic passphrase + age key FUERA del disco (gestor + papel/USB)
- [ ] Repo público limpio real (rama huérfana verificada gitleaks=0)
- [ ] 66 rutas /home/reeinharrrd → $HOME/%h
- [ ] Bootstrap único honesto con --check, --dry-run, checksums reales
- [ ] CI que prueba de verdad (bootstrap real, gitleaks historial, verify-claims)
- [ ] THREAT_MODEL.md honesto con estados verificables
- [ ] 3-2-1 backup real con copia fuera de sitio
- [ ] Sandbox real (ai-jail/nono spike)
- [ ] Permisos esquema válido + gobernanza plugins ≤10
- [ ] Presupuesto contexto ≤15 KB + sin ~/.env + wrapper ai
- [ ] Dueño único ruteo + MCP higiene + evals 20 tareas
- [ ] Perfiles personal/client + política antigravity

## Últimos cambios

- 2026-09-20: Seguridad completa (sops+age, gitleaks, permissions), THREAT_MODEL.md, README.md, examples/, CI, LiteLLM config, Langfuse/envsitter plugins, stow-sync.sh seguro, bootstrap con sops decrypt, repo público limpio push 3eda498
- 2026-09-11: purga completa (81G liberados: escolar 8°, docker muerto, caches), TW3 3.5.0 + sync server, matugen theming dinámico, zram, engram unificado 40→15 proyectos, opencode.db 8.6G→5.0G, commit 2767222
- 2026-09-10: audit + purge inicial (docker images, snaps, binarios muertos)

## Git

- dotfiles: main synced con origin (GitHub reeinharddd/dotfiles)
- ALL repos personales: remotes GitHub verificados synced