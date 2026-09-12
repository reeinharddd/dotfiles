# STATE.md: Estado vivo del sistema

> Actualizar al cerrar cada sesión de trabajo significativa.
> Par de entrada: STATE.md (qué está pasando) + WORKFLOW.md (cómo se trabaja).

# Estado

- Fecha: 2026-09-11
- Disco: 118G / 468G usados (27%, 327G libres)
- RAM: 13Gi total / ~8.6Gi en uso, zram zstd 6.9G activo
- Docker: 4 contenedores: wedo-db (:5433, healthy), qdrant (:6333), taskchampion-sync (:8090), mikedb (:5432, lab2 9°, detenido por diseño)
- Sesión opencode: múltiples activas (wedo + home): NUNCA matar

## Proyecto activo

- **wedo**: gestión hogar (~/projects/personal/wedo), 5+ procesos opencode
- **dispositivos 9°**: ~/School/dispositivos (lab2 + labC), cuatrimestre en curso

## Pendientes

- [ ] Verificar provider zen de hermes tras fix (hermes -z debe responder)
- [ ] Correr `just doc` semanal (timer doc-refresh lo automatiza)

## Últimos cambios

- 2026-09-11: purga completa (81G liberados: escolar 8°, docker muerto, caches), TW3 3.5.0 + sync server, matugen theming dinámico, zram, engram unificado 40→15 proyectos, opencode.db 8.6G→5.0G, commit 2767222
- 2026-09-10: audit + purge inicial (docker images, snaps, binarios muertos)

## Git

- dotfiles: main synced con origin (GitHub reeinharddd/dotfiles)
- ALL repos personales: remotes GitHub verificados synced
