#!/bin/bash
python3 -c "
import os
class Config:
    def __init__(self):
        self.defaults = {'PORT': 8080, 'DEBUG': False}
        self.config = {}
    def load(self):
        # 1. Defaults
        self.config.update(self.defaults)
        # 2. Config file
        # 3. .env file
        # 3. Env vars (highest priority)
        for k, v in os.environ.items():
            if k in self.defaults:
                self.config[k] = type(self.defaults[k])(v)
    def get(self, key):
        return self.config.get(key)

cfg = Config()
cfg.load()
print('Config loader structure valid!')
"