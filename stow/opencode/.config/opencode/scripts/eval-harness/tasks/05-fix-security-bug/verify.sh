#!/bin/bash
python3 -c "
def get_user_safe(cursor, user_id):
    cursor.execute('SELECT * FROM users WHERE id = ?', (user_id,))
    return cursor.fetchone()

# Test that it uses parameterized query
import sqlite3
conn = sqlite3.connect(':memory:')
conn.execute('CREATE TABLE users (id INTEGER, name TEXT)')
conn.execute('INSERT INTO users VALUES (1, "Alice")')
cursor = conn.cursor()
# This should work safely
result = get_user_safe(cursor, 1)
assert result[1] == 'Alice'
# Test injection attempt - should not execute
get_user_safe(cursor, "1; DROP TABLE users")
# If we get here without error, it's safe
print('SQL injection prevented!')
"