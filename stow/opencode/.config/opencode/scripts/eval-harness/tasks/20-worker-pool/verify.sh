#!/bin/bash
python3 -c "
import asyncio
async def worker_pool(tasks, concurrency, processor):
    semaphore = asyncio.Semaphore(concurrency)
    async def run_task(task):
        async with semaphore:
            return await processor(task)
    return await asyncio.gather(*[run_task(t) for t in tasks])

async def test():
    async def process(x):
        await asyncio.sleep(0.01)
        return x * 2
    results = await worker_pool(range(10), 3, process)
    assert results == [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]
    print('Worker pool works!')

import asyncio
asyncio.run(test())
"