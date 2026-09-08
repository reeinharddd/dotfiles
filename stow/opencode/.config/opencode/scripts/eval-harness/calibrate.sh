#!/usr/bin/env bash
# calibrate.sh — compara dos modelos en el eval harness para decidir el ruteo con datos.
#
# Uso:
#   calibrate.sh [model_free] [model_strong]
#
# Ejecuta las mismas tareas con un modelo free y uno fuerte, y muestra la tabla.
set -euo pipefail

FREE="${1:-opencode-zen/nemotron-3-ultra-free}"
STRONG="${2:-opencode-go/deepseek-v4-pro}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== CALIBRATION: $FREE (free) vs $STRONG (strong) ==="
F=$(bash "$ROOT/run-eval.sh" "$FREE" | tail -1)
S=$(bash "$ROOT/run-eval.sh" "$STRONG" | tail -1)
echo
echo "free:   $F"
echo "strong: $S"
echo
echo "Decisión: si strong >> free en FAILs críticos, el orquestador debe ser strong."
