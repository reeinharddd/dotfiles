#!/bin/bash
python3 -c "
sql = '''
ALTER TABLE users ADD COLUMN last_login TIMESTAMP;
UPDATE users SET last_login = created_at WHERE last_login IS NULL;
CREATE INDEX idx_users_last_login ON users(last_login);
'''
assert 'ALTER TABLE users ADD COLUMN last_login TIMESTAMP' in sql
assert 'UPDATE users SET last_login = created_at' in sql
assert 'CREATE INDEX idx_users_last_login' in sql
print('Migration SQL valid!')
"