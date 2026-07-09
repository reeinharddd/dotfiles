#!/bin/bash
# Verify complete job search setup

echo "🔍 Verifying Job Search Setup"
echo "=============================="

# 1. Check opencode config
echo ""
echo "1. OpenCode Configuration:"
if [ -f "/home/reeinharrrd/projects/dotfiles/opencode.json" ]; then
    mcp_count=$(python3 -c "import json; d=json.load(open('/home/reeinharrrd/projects/dotfiles/opencode.json')); print(len(d.get('mcp', {})))" 2>/dev/null || echo "0")
    agent_count=$(python3 -c "import json; d=json.load(open('/home/reeinharrrd/projects/dotfiles/opencode.json')); print(len(d.get('agent', {})))" 2>/dev/null || echo "0")
    cmd_count=$(python3 -c "import json; d=json.load(open('/home/reeinharrrd/projects/dotfiles/opencode.json')); print(len(d.get('command', {})))" 2>/dev/null || echo "0")
    echo "   ✅ opencode.json exists"
    echo "   📦 MCP Servers: $mcp_count"
    echo "   🤖 Agents: $agent_count"
    echo "   ⚡ Commands: $cmd_count"
else
    echo "   ❌ opencode.json not found"
fi

# 2. Check prompt files
echo ""
echo "2. Agent Prompts:"
prompts=(
    "job-search.txt"
    "cv-optimizer.txt"
    "profile-optimizer.txt"
    "interview-prep.txt"
)
for prompt in "${prompts[@]}"; do
    if [ -f "/home/reeinharrrd/ECC/.opencode/prompts/agents/$prompt" ]; then
        lines=$(wc -l < "/home/reeinharrrd/ECC/.opencode/prompts/agents/$prompt")
        echo "   ✅ $prompt ($lines lines)"
    else
        echo "   ❌ $prompt missing"
    fi
done

# 3. Check command files
echo ""
echo "3. Commands:"
commands=(
    "job-search.md"
    "cv-tailor.md"
    "profile-audit.md"
    "interview-prep.md"
    "job-track.md"
)
for cmd in "${commands[@]}"; do
    if [ -f "/home/reeinharrrd/ECC/.opencode/commands/$cmd" ]; then
        lines=$(wc -l < "/home/reeinharrrd/ECC/.opencode/commands/$cmd")
        echo "   ✅ $cmd ($lines lines)"
    else
        echo "   ❌ $cmd missing"
    fi
done

# 4. Check CV and directories
echo ""
echo "4. CV & Directories:"
dirs=(
    "/home/reeinharrrd/cv/master"
    "/home/reeinharrrd/cv/tailored"
    "/home/reeinharrrd/jobs"
    "/home/reeinharrrd/job-tracker"
    "/home/reeinharrrd/job-search-results"
)
for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "   ✅ $dir"
    else
        echo "   ❌ $dir missing"
    fi
done

if [ -f "/home/reeinharrrd/cv/master/master-cv.md" ]; then
    lines=$(wc -l < "/home/reeinharrrd/cv/master/master-cv.md")
    echo "   ✅ master-cv.md ($lines lines)"
else
    echo "   ❌ master-cv.md missing"
fi

# 5. Check scripts
echo ""
echo "5. Scripts:"
scripts=(
    "install-job-search-mcps.sh"
    "test-mcps.sh"
)
for script in "${scripts[@]}"; do
    if [ -f "/home/reeinharrrd/projects/dotfiles/scripts/$script" ]; then
        echo "   ✅ $script"
    else
        echo "   ❌ $script missing"
    fi
done

# 6. Check MCP server availability
echo ""
echo "6. MCP Server Availability (npm cache):"
mcps=(
    "firecrawl-mcp"
    "linkedin-mcp-server"
    "jobspy-mcp-server"
    "theirstack-mcp"
    "@playwright/mcp"
    "@modelcontextprotocol/server-github"
    "fantastic-jobs-mcp"
    "composio-mcp"
    "@modelcontextprotocol/server-filesystem"
    "@modelcontextprotocol/server-fetch"
    "@modelcontextprotocol/server-sequentialthinking"
    "@modelcontextprotocol/server-memory"
)
for mcp in "${mcps[@]}"; do
    if [ -d "$HOME/.npm/_npx" ] && find "$HOME/.npm/_npx" -name "*${mcp}*" -type d 2>/dev/null | head -1 | grep -q .; then
        echo "   ✅ $mcp (cached)"
    elif npm list -g "$mcp" 2>/dev/null | grep -q "$mcp"; then
        echo "   ✅ $mcp (global)"
    else
        echo "   ⚠️  $mcp (will auto-install on first use)"
    fi
done

# 7. Check uvx
echo ""
echo "7. uvx Tools:"
if command -v uvx &> /dev/null; then
    echo "   ✅ uvx $(uvx --version)"
    if uvx mcp-server-git --help 2>/dev/null | head -1 | grep -q "MCP Git Server"; then
        echo "   ✅ mcp-server-git available"
    else
        echo "   ⚠️  mcp-server-git (will install on first use)"
    fi
else
    echo "   ❌ uvx not installed"
fi

# 8. Environment variables
echo ""
echo "8. Environment Variables:"
env_vars=(
    "FIRECRAWL_API_KEY"
    "LINKEDIN_EMAIL"
    "LINKEDIN_PASSWORD"
    "THEIRSTACK_API_KEY"
    "GITHUB_PERSONAL_ACCESS_TOKEN"
    "COMPOSIO_API_KEY"
)
for var in "${env_vars[@]}"; do
    if [ -n "${!var}" ]; then
        echo "   ✅ $var is set"
    else
        echo "   ⚠️  $var not set"
    fi
done

# 9. Free tier accounts status
echo ""
echo "9. Free Tier Accounts (manual signup needed):"
accounts=(
    "Firecrawl: https://www.firecrawl.dev/ (500 credits/mo)"
    "TheirStack: https://theirstack.com/ (free tier)"
    "Composio: https://composio.dev/ (free tier)"
    "Resume Optimizer Pro: https://resumeoptimizerpro.com/ (free ATS check)"
    "Teal: https://www.tealhq.com/ (free unlimited resumes)"
    "HackerRank: https://www.hackerrank.com/ (free certs)"
    "Interviewing.io: https://interviewing.io/ (free tier mocks)"
    "CodeSignal: https://codesignal.com/ (free practice)"
    "LeetCode: https://leetcode.com/ (free daily)"
)
for acct in "${accounts[@]}"; do
    echo "   📝 $acct"
done

echo ""
echo "=============================="
echo "✅ Verification Complete"
echo "=============================="
echo ""
echo "Next Steps:"
echo "1. Sign up for free tiers above"
echo "2. Copy ~/.env.job-search.template to ~/.env and fill in API keys"
echo "3. source ~/.env"
echo "4. Restart opencode"
echo "5. Run: /job-search --discover --limit 5"
echo "6. Run: /profile-audit --platform both --mode full"
echo "7. Run: /interview-prep --schedule"
