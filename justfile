# ┌──────────────────────────────────────────────────────────────────┐
# │ justfile — Sistema Personal de Productividad 2026                │
# └──────────────────────────────────────────────────────────────────┘

set shell := ["bash", "-c"]

_default:
    @just --list

# ─── Tareas (Taskwarrior) ─────────────────────────────────────────

task desc:
    @task add "{{desc}}"

task-pro project desc:
    @task add project:{{project}} "{{desc}}"

tasks:
    @task list

today:
    @task list due:today

overdue:
    @task overdue

done id:
    @task {{id}} done

start id:
    @echo "==> Iniciando: {{id}}"
    @task {{id}} start
    @timew start "{{id}}" 2>/dev/null || echo "timew: tracking started"

stop:
    @task rc:_forcecolor:yes +ACTIVE stop 2>/dev/null || true
    @timew stop 2>/dev/null || true
    @echo "Stopped"

# ─── Journal (jrnl) ──────────────────────────────────────────────

note entry:
    @jrnl "{{entry}}"

journal:
    @jrnl

notes:
    @jrnl --short today 2>/dev/null || echo "No entries today"

write-journal:
    @jrnl -today

# ─── Enfoque (Pomodoro) ─────────────────────────────────────────

focus minutes task:
    @bash scripts/pomodoro.sh {{minutes}} {{task}}

pomodoro:
    @bash scripts/pomodoro.sh 25

# ─── Tiempo (Timewarrior) ───────────────────────────────────────

time:
    @timew summary today

week-time:
    @timew summary thisweek

track activity:
    @timew start "{{activity}}"

# ─── Revisiones ─────────────────────────────────────────────────

daily:
    @bash scripts/daily-review.sh

end-day:
    @bash scripts/end-day.sh

# ─── Notificaciones ─────────────────────────────────────────────

notify title msg:
    @notify-send "{{title}}" "{{msg}}"

push title msg:
    @if [ -f ~/.config/ntfy/topic ]; then \
        ntfy publish $$(cat ~/.config/ntfy/topic) "{{title}}: {{msg}}"; \
    else \
        echo "ntfy: configurar ~/.config/ntfy/topic primero"; \
    fi

# ─── Clipboard (cliphist) ──────────────────────────────────────

clip:
    @cliphist list | head -30

clip-pick:
    @cliphist list | fuzzel --dmenu --prompt="Clipboard: " | cliphist decode | wl-copy

clip-clear:
    @cliphist wipe

# ─── Calendario (khal) ──────────────────────────────────────────

cal:
    @khal calendar --days 1 2>/dev/null || echo "khal no configurado"

week:
    @khal calendar --days 7 2>/dev/null || echo "khal no configurado"

# ─── Process queue (pueue) ─────────────────────────────────────

pq cmd:
    @pueue add "{{cmd}}"

pq-list:
    @pueue status

pq-log id:
    @pueue log {{id}}

pq-pause:
    @pueue pause

pq-resume:
    @pueue start

pq-clean:
    @pueue clean

# Inicia pueued via systemd (daemon v4 funcionando)
pq-daemon:
    @systemctl --user start pueued.service
    @sleep 1
    @pueue status 2>&1 | head -3

# ─── Fuzzy finders (tv, fzf, broot) ────────────────────────────

tv-files:
    @tv

tv-history:
    @atuin search --interactive

tree:
    @broot

find query:
    @fd "{{query}}"

# ─── HTTP (xh) ────────────────────────────────────────────────

http url:
    @xh {{url}}

# ─── Sistema ────────────────────────────────────────────────────

status:
    @echo "Tareas:   $(task count 2>/dev/null || echo 'N/A')"
    @echo "Tiempo:   $(timew summary today 2>/dev/null | tail -1 || echo '0')"
    @echo "RAM:      $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    @echo "Bateria:  $(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)%"
    @echo "Pueue:    $(pueue status 2>/dev/null | head -1 || echo 'daemon down')"
    @echo "Disk:     $(df -h / | tail -1 | awk '{print $5}')"

sysinfo:
    @fastfetch

# ─── AI (opencode) ──────────────────────────────────────────────

ai:
    @opencode

ai-work session:
    @opencode -s {{session}}

# ─── Dotfiles ───────────────────────────────────────────────────

sync:
    @echo "Restowing all packages..."
    @bash scripts/stow-sync.sh
    @echo "Done"

check:
    @echo "Checking stow..."
    @bash scripts/stow-check.sh

ship msg:
    @cd {{justfile_directory()}} && \
    git add -A && \
    git commit -m "{{msg}}" && \
    git push

# ─── AI Life Agent ──────────────────────────────────────────────

hey:
    @echo "Iniciando asistente personal..."
    @bash scripts/life-agent.sh

# ─── Recordatorios ──────────────────────────────────────────────

remind msg datetime:
    @mkdir -p ~/.local/share/reminders
    @echo "$(date -d '{{datetime}}' '+%H:%M') - {{msg}}" >> ~/.local/share/reminders/today.txt
    @echo "Recordatorio: {{msg}} a las {{datetime}}"
    @systemd-run --user --on-calendar="{{datetime}}" --unit=reminder-$(echo {{msg}} | tr ' ' '-') notify-send "Recordatorio" "{{msg}}"

# ─── 2026 Tools — Better alternatives ────────────────────────────

# gum — interactive shell prompts
gum-choose choices:
    @gum choose {{choices}}

gum-input prompt:
    @gum input --placeholder "{{prompt}}"

gum-confirm msg:
    @gum confirm "{{msg}}"

gum-spin msg cmd:
    @gum spin --spinner dot --title "{{msg}}" -- {{cmd}}

# gping — ping with graph
gping target:
    @gping {{target}}

# lnav — log navigator
logs:
    @sudo lnav /var/log/syslog /var/log/auth.log

# onefetch — git repo info
onefetch:
    @onefetch

# gdu — interactive disk usage
disk-scan path:
    @gdu {{path}}

# restic — backups
backup:
    @bash scripts/backup-restic.sh

restore:
    @restic restore latest --target /tmp/restore

snapshots:
    @restic snapshots

# ai agents
ai-orchestrate:
    @opencode -p "orchestrate"

# ─── Hyprland ──────────────────────────────────────────────────

hypr-session:
    @echo "Para activar Hyprland: logout → seleccionar Hyprland en GDM"

hypr-reload:
    @hyprctl reload

# ─── Restic backup timer ───────────────────────────────────────

backup-install-timer:
    @bash scripts/install-restic-timer.sh

# ─── Atuin sync ──────────────────────────────────────────────

atuin-register:
    @echo "Para registrar Atuin: atuin register -u <username> -e <email>"
    @echo "Para login: atuin login -u <username>"
    @echo "Para sync: atuin sync"

# ─── ntfy topic ───────────────────────────────────────────────

ntfy-setup topic:
    @echo "{{topic}}" > ~/.config/ntfy/topic
    @chmod 600 ~/.config/ntfy/topic
    @echo "Topic configurado. Instala ntfy app en el telefono y subscribe."
    @echo "Test: ntfy publish $$(cat ~/.config/ntfy/topic) 'Hola desde CLI'"
