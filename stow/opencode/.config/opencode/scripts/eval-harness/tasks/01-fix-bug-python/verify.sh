#!/bin/bash
python3 -c "
def fibonacci(n):
    if n <= 1:
        return n
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a

# Test cases
assert fibonacci(0) == 0
assert fibonacci(1) == 1
assert fibonacci(10) == 55
assert fibonacci(50) == 12586269025
# Performance test - use smaller n for reasonable time
import time
start = time.time()
result = fibonacci(100000)
elapsed = time.time() - start
assert elapsed < 1.0, f'Too slow: {elapsed}s'
print('All tests passed!')
"
