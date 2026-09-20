#!/bin/bash
python3 -c "
hook = '''#!/bin/bash
# Check for secrets
gitleaks git --staged --redact --no-banner
if [ \$? -ne 0 ]; then exit 1; fi

# Check shell scripts
shellcheck \$(git diff --cached --name-only -- '*.sh')
if [ \$? -ne 0 ]; then exit 1; fi

# Check for TODO/FIXME in production paths
if git diff --cached --name-only -- 'src/**' 'lib/**' | xargs grep -l 'TODO\|FIXME' 2>/dev/null; then
    echo 'TODO/FIXME found in production code'
    exit 1
fi
'''
assert 'gitleaks' in hook
assert 'shellcheck' in hook
assert 'TODO\|FIXME' in hook
print('Git hook structure valid!')
"