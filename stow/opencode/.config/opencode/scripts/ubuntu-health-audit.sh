#!/usr/bin/env bash
set -uo pipefail

# Read-only workstation audit. It never installs, removes, reloads, or changes services.
printf 'Ubuntu health audit (%s)\n' "$(date -Is)"
printf '\n[system]\n'
sed -n 's/^\(PRETTY_NAME\|VERSION_ID\)=/\1=/p' /etc/os-release 2>/dev/null
uname -r
df -hT / /home /tmp 2>/dev/null
free -h

printf '\n[package-updates]\n'
if command -v apt >/dev/null 2>&1; then
  count=$(apt list --upgradable 2>/dev/null | awk 'NR > 1 {n++} END {print n+0}')
  printf 'upgradable=%s\n' "$count"
fi
if command -v snap >/dev/null 2>&1; then
  snap refresh --list 2>/dev/null | sed -n '1,20p'
fi

printf '\n[services]\n'
systemctl --failed --no-legend 2>/dev/null || true

printf '\n[security]\n'
if command -v ufw >/dev/null 2>&1; then ufw status 2>/dev/null | sed -n '1,12p'; else echo 'ufw=not-installed'; fi
if command -v aa-status >/dev/null 2>&1; then aa-status 2>/dev/null | sed -n '1,12p'; else echo 'apparmor-tools=not-installed'; fi

printf '\n[mise]\n'
if command -v mise >/dev/null 2>&1; then
  mise ls 2>/dev/null | sed -n '1,80p'
  printf 'missing_tools='; mise ls 2>/dev/null | awk '$2 == "missing" {printf "%s ", $1} END {print ""}'
fi

printf '\n[path-drift]\n'
for path in \
  "$HOME/.local/share/mise/installs/go/1.26.4" \
  "$HOME/.local/share/mise/installs/node/24.16.0" \
  "$HOME/.local/share/mise/installs/python/3.14.6"; do
  [[ -e "$path" ]] && printf 'stale=%s\n' "$path"
done

printf '\n[large-state]\n'
du -sh "$HOME/.local/share/opencode" "$HOME/.cache/opencode" "$HOME/.cache/ms-playwright" "$HOME/.cargo" "$HOME/.npm" 2>/dev/null
