#!/bin/bash
# Start Job Search System - Run after filling ~/.env

echo "🚀 Starting Job Search System"
echo "=============================="

# Load environment
if [ -f "$HOME/.env" ]; then
    echo "📥 Loading ~/.env..."
    set -a
    source "$HOME/.env"
    set +a
    echo "✅ Environment loaded"
else
    echo "❌ ~/.env not found. Copy from ~/.env.job-search.template and fill in values"
    exit 1
fi

# Verify required vars
required=("FIRECRAWL_API_KEY" "LINKEDIN_EMAIL" "LINKEDIN_PASSWORD" "THEIRSTACK_API_KEY" "GITHUB_PERSONAL_ACCESS_TOKEN")
missing=()
for var in "${required[@]}"; do
    if [ -z "${!var}" ] || [[ "${!var}" == *"xxxxx"* ]]; then
        missing+=("$var")
    fi
done

if [ ${#missing[@]} -gt 0 ]; then
    echo "⚠️  Missing/incomplete required variables:"
    for var in "${missing[@]}"; do
        echo "   - $var"
    done
    echo "Edit ~/.env and fill in real values"
    exit 1
fi

# Verify opencode config
echo ""
echo "🔧 Verifying opencode..."
if opencode --version 2>/dev/null; then
    echo "✅ opencode available"
else
    echo "❌ opencode not in PATH. Install: npm install -g opencode-ai"
    exit 1
fi

# Test MCP connections
echo ""
echo "🔌 Testing MCP servers..."
mcps=("firecrawl" "theirstack" "github" "playwright" "filesystem" "memory")
for mcp in "${mcps[@]}"; do
    echo -n "  $mcp... "
    if timeout 15 opencode mcp test "$mcp" 2>&1 | grep -q "OK\|connected\|ready"; then
        echo "✅"
    else
        echo "⚠️  (will connect on first use)"
    fi
done

# Show available commands
echo ""
echo "📋 Available Commands:"
echo "  /job-search --discover --limit 10        # Discover jobs"
echo "  /job-search --full                       # Full pipeline"
echo "  /cv-tailor --job-id <id>                 # Tailor CV"
echo "  /profile-audit --platform both           # Audit profiles"
echo "  /interview-prep --schedule               # Prep schedule"
echo "  /job-track --add                         # Track application"
echo "  /job-track --stats                       # Pipeline stats"

echo ""
echo "=============================="
echo "✅ System Ready!"
echo "=============================="
echo ""
echo "Quick Start:"
echo "1. /job-search --discover --keywords '.NET Architect,Angular Architect' --limit 10"
echo "2. Review results in ~/job-search-results/"
echo "3. /cv-tailor --job-id <top_match>"
echo "4. /job-track --add (interactive)"
echo "5. /profile-audit --platform both --mode fix --apply-fixes"
