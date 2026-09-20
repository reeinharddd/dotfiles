#!/bin/bash
python3 -c "
import yaml
a = {'a': 1, 'b': 2, 'c': {'x': 1}}
b = {'a': 1, 'b': 3, 'd': 4, 'c': {'x': 2}}
def diff(a, b, path=''):
    added = set(b) - set(a)
    removed = set(a) - set(b)
    changed = {k for k in set(a) & set(b) if a[k] != b[k]}
    for k in added: print(f'+ {path}{k}: {b[k]}')
    for k in removed: print(f'- {path}{k}: {a[k]}')
    for k in changed: print(f'~ {path}{k}: {a[k]} -> {b[k]}')
    for k in set(a) & set(b):
        if isinstance(a[k], dict) and isinstance(b[k], dict):
            diff(a[k], b[k], f'{path}{k}.')
diff(a, b)
print('YAML diff works!')
"