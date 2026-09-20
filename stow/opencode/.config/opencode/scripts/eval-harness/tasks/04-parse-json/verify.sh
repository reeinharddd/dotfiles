#!/bin/bash
python3 -c "
import json
def parse_user(json_str):
    try:
        data = json.loads(json_str)
        required = ['id', 'name', 'email']
        for field in required:
            if field not in data:
                return {'error': f'missing {field}'}
        return {k: data[k] for k in required}
    except json.JSONDecodeError:
        return {'error': 'invalid json'}

assert parse_user('{"id": 1, "name": "John", "email": "j@j.com"}') == {'id': 1, 'name': 'John', 'email': 'j@j.com'}
assert parse_user('{"id": 1}')['error'] == 'missing name'
assert parse_user('invalid')['error'] == 'invalid json'
print('All tests passed!')
"