#!/usr/bin/env bash
# run-eval.sh — eval harness para agentes opencode con verifiers funcionales.
#
# Uso:
#   run-eval.sh [model]          # corre todas las tareas con ese modelo
#   MODEL=<m> run-eval.sh
#
# Cada tarea en tasks/<name>/:
#   prompt.txt   — instrucción para el agente
#   verify.sh    — verifier funcional (exit 0 = pass)
#   otros archivos = proyecto inicial que se copia al workspace del agente
#
# Mide: pass/fail + tiempo. El costo lo reporta Metronous.
set -euo pipefail

MODEL="${1:-${MODEL:-opencode-zen/nemotron-3-ultra-free}}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0
mkdir -p /tmp/opencode/eval

for task in "$ROOT"/tasks/*/; do
	name="$(basename "$task")"
	tmp="$(mktemp -d /tmp/opencode/eval/"$name".XXXXXX)"
	cp -r "$task"/. "$tmp"/ 2>/dev/null || true
	rm -f "$tmp"/prompt.txt "$tmp"/verify.sh

	echo "== $name (model: $MODEL) =="
	start="$(date +%s)"
	(cd "$tmp" && opencode run "$(cat "$task/prompt.txt")" --model "$MODEL") >/tmp/opencode/eval/"$name".log 2>&1 || true
	end="$(date +%s)"

	if (cd "$tmp" && bash "$task/verify.sh" >/dev/null 2>&1); then
		echo "  PASS ($((end - start))s)"
		PASS=$((PASS + 1))
	else
		echo "  FAIL ($((end - start))s)"
		FAIL=$((FAIL + 1))
	fi
	rm -rf "$tmp"
done

echo "RESULT: $PASS pass / $FAIL fail (model: $MODEL)"
