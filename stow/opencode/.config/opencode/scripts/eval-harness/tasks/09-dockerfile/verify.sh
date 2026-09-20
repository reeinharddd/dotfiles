#!/bin/bash
python3 -c "
dockerfile = '''
FROM python:3.12-slim
RUN useradd -m appuser
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
USER appuser
HEALTHCHECK CMD curl -f http://localhost:8000/health || exit 1
CMD ["python", "app.py"]
'''
assert 'USER appuser' in dockerfile
assert 'HEALTHCHECK' in dockerfile
assert 'python:3.12-slim' in dockerfile
print('Dockerfile structure valid!')
"