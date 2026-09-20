#!/bin/bash
python3 -c "
import asyncio, time
class TokenBucket:
    def __init__(self, rate, burst):
        self.rate = rate
        self.burst = burst
        self.tokens = burst
        self.last = time.monotonic()
    async def take(self):
        while True:
            now = time.monotonic()
            self.tokens = min(self.burst, self.tokens + (now - self.last) * self.rate)
            self.last = now
            if self.tokens >= 1:
                self.tokens -= 1
                return True
            await asyncio.sleep(0.01)

async def test():
    tb = TokenBucket(10, 5)
    for _ in range(5):
        assert await tb.take() == True
    start = time.monotonic()
    await tb.take()
    elapsed = time.monotonic() - start
    assert elapsed >= 0.09
    print('Rate limiter works!')

import asyncio
asyncio.run(test())
"