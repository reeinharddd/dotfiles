#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import sys
sys.path.insert(0, '.')
from buggy import total
assert total([1, 2, 3]) == 6, "total([1,2,3])"
assert total([]) == 0, "total([])"
assert total([-1, 1]) == 0, "total([-1,1])"
print("total OK")
PY
