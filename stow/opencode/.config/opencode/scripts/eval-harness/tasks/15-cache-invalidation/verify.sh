#!/bin/bash
python3 -c "
from collections import OrderedDict
import time
class TTLCache:
    def __init__(self, maxsize=100, ttl=300):
        self.cache = OrderedDict()
        self.ttl = ttl
        self.maxsize = maxsize
    def get(self, key):
        if key not in self.cache:
            return None
        value, expiry = self.cache[key]
        if time.time() > expiry:
            del self.cache[key]
            return None
        self.cache.move_to_end(key)
        return value
    def set(self, key, value):
        if key in self.cache:
            self.cache.move_to_end(key)
        elif len(self.cache) >= self.maxsize:
            self.cache.popitem(last=False)
        self.cache[key] = (value, time.time() + 300)

cache = TTLCache(2, 1)
cache.set('a', 1)
cache.set('b', 2)
assert cache.get('a') == 1
cache.set('c', 3)  # evicts 'a'
assert cache.get('a') is None
assert cache.get('b') == 2
print('TTL Cache works!')
"