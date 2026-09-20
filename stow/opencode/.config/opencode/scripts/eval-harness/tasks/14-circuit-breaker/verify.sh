#!/bin/bash
python3 -c "
import time
class CircuitBreaker:
    def __init__(self, failure_threshold=5, timeout=30):
        self.failures = 0
        self.threshold = failure_threshold
        self.timeout = timeout
        self.state = 'closed'
        self.last_failure = 0
    def call(self, func, *args):
        if self.state == 'open':
            if time.time() - self.last_failure > self.timeout:
                self.state = 'half-open'
            else:
                raise Exception('Circuit open')
        try:
            result = func(*args)
            if self.state == 'half-open':
                self.state = 'closed'
                self.failures = 0
            return result
        except Exception as e:
            self.failures += 1
            self.last_failure = time.time()
            if self.failures >= self.threshold:
                self.state = 'open'
            raise

cb = CircuitBreaker(3, 1)
for _ in range(3):
    try: cb.call(lambda: 1/0)
    except: pass
assert cb.state == 'open'
print('Circuit breaker works!')
"