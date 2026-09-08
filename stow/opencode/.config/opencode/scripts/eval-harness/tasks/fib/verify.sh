#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import sys
sys.path.insert(0, '.')
from lib import fib
assert fib(0) == 0, "fib(0)"
assert fib(1) == 1, "fib(1)"
assert fib(2) == 1, "fib(2)"
assert fib(10) == 55, "fib(10)"
assert fib(20) == 6765, "fib(20)"
print("fib OK")
PY
