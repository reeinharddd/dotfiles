#!/usr/bin/env bash
set -euo pipefail
[ -f README.md ] || {
	echo "README.md missing"
	exit 1
}
lines="$(wc -l <README.md)"
[ "$lines" -eq 3 ] || {
	echo "expected 3 lines, got $lines"
	exit 1
}
echo "readme OK"
