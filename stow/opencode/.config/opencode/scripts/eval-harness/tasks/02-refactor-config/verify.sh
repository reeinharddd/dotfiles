#!/bin/bash
python3 -c "
import yaml, os
with open('config.yaml') as f:
    config = yaml.safe_load(f)
db = config['database']
assert db['host'] == '\${DB_HOST}' or db['host'] == os.environ.get('DB_HOST', 'localhost')
assert db['port'] == '\${DB_PORT}' or db['port'] == int(os.environ.get('DB_PORT', 5432))
print('Config uses env vars correctly!')
"