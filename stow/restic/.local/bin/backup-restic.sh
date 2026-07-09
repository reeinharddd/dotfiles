#!/bin/bash
# ┌──────────────────────────────────────────────────────────────────┐
# │ Restic backup — cifrado + dedup + cloud                            │
# │ https://restic.readthedocs.io/                                       │
# └──────────────────────────────────────────────────────────────────┘

set -euo pipefail

# Configuracion
REPO="${RESTIC_REPO:-/var/backups/restic}"
RESTORE_DIR="${RESTIC_RESTORE_DIR:-/tmp/restore}"
PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-$HOME/.config/restic/passphrase}"
EXCLUDE_FILE="$HOME/.config/restic/exclude"

# Cargar password si existe
[ -f "$PASSWORD_FILE" ] || {
    echo "Error: no password file at $PASSWORD_FILE"
    echo "Generate: head -c 32 /dev/urandom | base64 > $PASSWORD_FILE"
    echo "Then:    export RESTIC_PASSWORD_COMMAND=\"cat $PASSWORD_FILE\""
    exit 1
}
export RESTIC_PASSWORD_FILE="$PASSWORD_FILE"

# Crear repo si no existe
if [ ! -d "$REPO" ] && [ ! -f "$REPO/config" ]; then
    echo "Inicializando repo en $REPO..."
    restic init
fi

# Backup
echo "==> Backup iniciado: $(date)"
restic backup \
    --tag auto \
    --exclude-caches \
    --exclude-file="$EXCLUDE_FILE" \
    --one-file-system \
    /home/reeinharrrd/Documents \
    /home/reeinharrrd/projects \
    /home/reeinharrrd/.config \
    /home/reeinharrrd/dotfiles \
    /home/reeinharrrd/.local/bin \
    /home/reeinharrrd/.zsh_history \
    /home/reeinharrrd/.ssh \
    /home/reeinharrrd/.gnupg

echo "==> Backup terminado: $(date)"

# Retention
echo "==> Aplicando retention..."
restic forget \
    --keep-hourly 6 \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    --keep-yearly 2 \
    --prune

# Stats
echo "==> Stats:"
restic stats

echo "==> Snapshots:"
restic snapshots --latest 5
