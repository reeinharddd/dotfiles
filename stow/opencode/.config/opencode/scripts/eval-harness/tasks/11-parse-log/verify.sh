#!/bin/bash
python3 -c "
import re
log_line = '192.168.1.1 - - [10/Oct/2023:13:55:36 +0000] "GET /api/users HTTP/1.1" 200 1024 0.045'
pattern = r'(\S+) - - \[([^\]]+)\] "(\S+) (\S+) HTTP/\d\.\d" (\d+) (\d+) (\S+)'
match = re.match(pattern, log_line)
assert match is not None
ip, timestamp, method, path, status, size, rt = match.groups()
assert ip == '192.168.1.1'
assert method == 'GET'
assert path == '/api/users'
assert status == '200'
print('Log parsing works!')
"