# Option D — Arquitectura de Sistema Personal Hibrido

> Fecha: 2026-07-03
> Stack base: Ghostty + Herdr + Zsh + Mise + Stow + Opencode

---

## Vision General

Un sistema donde el AI asiste en **cualquier aspecto de la vida**, no solo codigo.
El AI es el interprete de lenguaje natural, y el sistema subyacente (Taskwarrior, systemd, just, etc.)
es el ejecutor. Hablas, y las cosas pasan.

---

## Arquitectura (5 Capas)

```
┌──────────────────────────────────────────────────────────────────┐
│                      CAPA 5 — INTERFAZ                          │
│                                                                  │
│   Terminal (Ghostty)    Hotkey    Telegram/Web    Voice (whisper)│
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│                    CAPA 4 — AI ASSISTANT                         │
│                                                                  │
│   Opencode / Claude Code (sesion persistente "vida")            │
│   MCP servers: codebase-memory, engram (memoria persistente)    │
│   Custom MCPs: taskwarrior, calendar, notes                     │
│                                                                  │
│   Funcion: Lenguaje natural → comandos del sistema              │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│                  CAPA 3 — WORKFLOWS (Justfile)                   │
│                                                                  │
│   just daily    → revision diaria (tareas, clima, calendario)    │
│   just weekly   → revision semanal (logros, pendientes, retro)   │
│   just task     → agregar tarea rapida                           │
│   just note     → capturar nota rapida                           │
│   just focus    → iniciar sesion de enfoque (pomodoro)           │
│   just end-day  → cerrar dia, registrar tiempo, resumen          │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│                  CAPA 2 — SERVICE LAYER                          │
│                                                                  │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│   │Taskwarrior│  │Timewarrior│  │ Systemd  │  │   notify-send  │  │
│   │tareas     │  │tiempo    │  │ timers   │  │   + ntfy       │  │
│   │proyectos  │  │reportes  │  │schedule  │  │notificaciones  │  │
│   └──────────┘  └──────────┘  └──────────┘  └───────────────┘  │
│                                                                  │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│   │ khal     │  │ jrnl     │  │pass/bitw │  │   Sync (git)   │  │
│   │calendario│  │journal   │  │secrets   │  │   respaldo     │  │
│   └──────────┘  └──────────┘  └──────────┘  └───────────────┘  │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│                   CAPA 1 — CORE SYSTEM                           │
│                                                                  │
│   Ghostty → Herdr → Zsh → Mise (tools) → Stow (dotfiles)       │
│   auto-cpufreq | ufw | TLP | swappiness=10 | battery=80%        │
│   Docker (n8n, DBs, etc.)                                        │
└──────────────────────────────────────────────────────────────────┘
```

---

## Componentes Detallados

### CAPA 4 — AI Assistant

**Concepto:** Un asistente persistente estilo "Hermes" que siempre esta disponible.
No abrir una sesion cada vez, sino tener un agente corriendo o invocable al instante.

**Opciones concretas:**

| Opcion | Descripcion | Pros |
|--------|-------------|------|
| **A. Sesion Opencode persistente** | Una sesion dedicada que mantiene historial | Contexto largo, memoria de sesion |
| **B. Claude Code + tools MCP** | Claude Code con MCP servers para taskwarrior/etc | Mas autonomo, puede ejecutar herramientas |
| **C. Script custom "asistente"** | Un script bash que recibe query y la procesa | Liviano, rapido, sin dependencias |
| **D. n8n + AI** | n8n con modulo de AI Agent (OpenAI/Claude) | GUI visual, webhooks, integraciones |

**Recomendacion inicial:** Opcion B + C — Claude Code como el "cerebro" con tools,
y scripts `just` como atajos directos.

**Ejemplo de uso:**
```bash
# En lugar de:
task add pay electricity due:tomorrow

# Dices:
claude "recuerdame pagar la luz manana a las 10am"

# El AI:
# 1. Crea tarea en Taskwarrior
# 2. Configura systemd timer para recordatorio
# 3. Confirma en terminal
```

### CAPA 3 — Workflows (Justfile)

Workflows modulares para la vida diaria:

```
just daily     → Muestra calendario + tareas del dia + clima + ultimos commits
just weekly    → Revision semanal: tareas completadas, pendientes, objetivos
just focus [n] → Bloque de enfoque de n minutos (pomodoro con notificacion)
just task      → Agrega tarea rapida (pide titulo, proyecto, deadline)
just note      → Captura nota a jrnl/journal
just log       → Registra que estas haciendo (timewarrior start/stop)
just review    → Revisa el dia: que hiciste, que falta, que aprendiste
just ship      → Commit + push al dotfiles repo
```

### CAPA 2 — Service Layer

**Taskwarrior:** Gestion de tareas CLI.
- Proyectos: `work`, `personal`, `bills`, `health`, `learning`
- Prioridades, deadlines, tags
- Urgencia automatica
- Sync via git

**Timewarrior:** Tracking de tiempo.
- Integrado con taskwarrior
- Reportes diarios/semanales
- Facturacion potencial

**Systemd timers:** Schedule de todo.
- `~/.config/systemd/user/`
- Recordatorios: `taskwarrior-reminder.timer`
- Backups: `dotfiles-backup.timer`
- Daily review: `daily-review.timer`
- Weekly review: `weekly-review.timer`

**notify-send + ntfy:** Notificaciones.
- Desktop: `notify-send "Recordatorio" "Pagar la luz"`
- Telefono via ntfy: `curl -d "mensaje" ntfy.sh/tu-topic`

**khal:** Calendario CLI (CalDAV).
- Google Calendar sync via vdirsyncer

**jrnl:** Journaling CLI.
- `jrnl today: working on system architecture`
- Cifrado opcional

### CAPA 1 — Core (ya implementado)

Todo lo que hicimos hasta ahora.

---

## Plan de Implementacion

### Fase 1 — Base (hoy)
1. Instalar Taskwarrior + Timewarrior
2. Crear justfile con workflows basicos (`just daily`, `just task`, `just note`)
3. Integrar con Claude Code via MCP

### Fase 2 — Calendario + Notas
4. Instalar khal + vdirsyncer (calendario)
5. Instalar jrnl (journal)
6. Notificaciones ntfy (push al telefono)

### Fase 3 — AI Assistant persistente
7. Crear "life agent" — sesion opencode/claude Code dedicada
8. MCP servers personalizados (taskwarrier, calendar)
9. Integracion con voz (whisper)

### Fase 4 — Pulido
10. Systemd timers para todo
11. Sync automatico de configs
12. Dashboard web opcional (n8n)

---

## Sobre Hermes / OpenCLAW

El concepto de "Hermes" (un asistente AI persistente con acceso a herramientas del sistema)
es exactamente lo que esta arquitectura implementa. La diferencia es que en lugar de
un asistente standalone, usamos Claude Code / Opencode como el motor AI porque:

- Ya lo tienes instalado y configurado
- Tiene acceso a MCP servers (memoria persistente, filesystem, etc.)
- Puede ejecutar comandos y scripts
- Mantiene contexto de conversacion
- Se invoca con un comando simple

Para la experiencia "Hermes" (siempre disponible, conversacional):
- Un alias `alias hey="claude --model claude-sonnet-4"` abre una sesion express
- O un `systemd --user` service que mantiene una sesion abierta
- O un script `~/.local/bin/hermes` que canaliza queries a Claude con un prompt de sistema

Que opinas? Le entramos a la Fase 1?
