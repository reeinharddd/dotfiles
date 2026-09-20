#!/bin/bash
python3 -c "
import pytest
import re

def is_valid_email(email):
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))

# Test cases
assert is_valid_email('test@example.com') == True
assert is_valid_email('user.name@domain.org') == True
assert is_valid_email('invalid') == False
assert is_valid_email('@no-local.com') == False
assert is_valid_email('no-at.com') == False
assert is_valid_email('test@') == False
print('All email validation tests passed!')
"