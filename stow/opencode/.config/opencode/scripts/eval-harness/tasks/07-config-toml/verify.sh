#!/bin/bash
python3 -c "
import toml
config = {
    'database': {'host': 'localhost', 'port': 5432},
    'api': {'port': 8080},
    'logging': {'level': 'INFO'}
}
required = ['database', 'api', 'logging']
defaults = {'api': {'port': 8000}, 'logging': {'level': 'DEBUG'}}
for section in required:
    if section not in config:
        config[section] = {}
    if section in defaults:
        for k, v in defaults[section].items():
            config[section].setdefault(k, v)
assert config['api']['port'] == 8080
assert config['logging']['level'] == 'INFO'
print('Config validation works!')
"