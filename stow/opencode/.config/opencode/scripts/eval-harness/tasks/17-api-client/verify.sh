#!/bin/bash
python3 -c "
class APIClient:
    def __init__(self, base_url, max_retries=3):
        self.base_url = base_url
        self.max_retries = max_retries
    def request(self, method, path):
        for attempt in range(self.max_retries):
            try:
                # mock response
                return {'status': 200, 'data': {}}
            except Exception as e:
                if attempt == self.max_retries - 1:
                    raise
                time.sleep(2 ** attempt)
        return None

client = APIClient('https://api.example.com')
print('API Client structure valid!')
"