#!/bin/bash
# Install Job Search MCP Servers and Tools
# Run: bash scripts/install-job-search-mcps.sh

set -e

echo "🚀 Installing Job Search MCP Servers & Tools"
echo "============================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check prerequisites
check_cmd() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 found: $("$1" --version 2>/dev/null | head -1)"
        return 0
    else
        echo -e "${RED}✗${NC} $1 not found"
        return 1
    fi
}

echo ""
echo "📋 Checking prerequisites..."
check_cmd node
check_cmd npm
check_cmd npx
check_cmd uvx
check_cmd bun
check_cmd git
check_cmd gh

# Install MCP servers via npm/npx (they auto-install on first run)
echo ""
echo "📦 Pre-installing MCP servers (first run cache)..."

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
    echo -e "${YELLOW}→${NC} Caching $mcp..."
    timeout 60 npx -y "$mcp" --help 2>/dev/null || true
    echo -e "${GREEN}✓${NC} $mcp cached"
done

# Install Playwright browsers
echo ""
echo "🌐 Installing Playwright browsers..."
npx -y playwright install chromium 2>/dev/null || true
npx -y playwright install firefox 2>/dev/null || true
npx -y playwright install webkit 2>/dev/null || true

# Install uvx tools
echo ""
echo "🐍 Installing uvx tools..."
uvx mcp-server-git --help 2>/dev/null || true

# Verify opencode config
echo ""
echo "⚙️  Verifying opencode configuration..."
if [ -f "/home/reeinharrrd/projects/dotfiles/opencode.json" ]; then
    echo -e "${GREEN}✓${NC} opencode.json exists"
    # Validate JSON
    if python3 -m json.tool /home/reeinharrrd/projects/dotfiles/opencode.json > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} opencode.json valid JSON"
    else
        echo -e "${RED}✗${NC} opencode.json invalid JSON"
    fi
else
    echo -e "${RED}✗${NC} opencode.json not found"
fi

# Check for required environment variables
echo ""
echo "🔐 Checking environment variables (set these in your shell rc)..."
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
        echo -e "${GREEN}✓${NC} $var is set"
    else
        echo -e "${YELLOW}⚠${NC} $var not set (required for $var)"
    fi
done

# Create .env template
echo ""
echo "📝 Creating .env template..."
cat > /home/reeinharrrd/.env.job-search.template << 'EOF'
# Job Search MCP Environment Variables
# Copy to ~/.env and fill in your values
# Then: source ~/.env

# Firecrawl - Web scraping & research (free tier: 500 credits/mo)
# Get at: https://www.firecrawl.dev/
FIRECRAWL_API_KEY=fc-xxxxxxxxxxxxxxxx

# LinkedIn - Your LinkedIn credentials (for linkedin-mcp-server)
# Uses your logged-in browser session
LINKEDIN_EMAIL=your-email@example.com
LINKEDIN_PASSWORD=your-password

# TheirStack - Job data API (free tier available)
# Get at: https://theirstack.com/
THEIRSTACK_API_KEY=ts_xxxxxxxxxxxxxxxx

# GitHub - Personal Access Token (classic, repo + read:org scopes)
# Create at: https://github.com/settings/tokens
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxxxxxxxxxxxxxxx

# Composio - 250+ integrations (free tier available)
# Get at: https://composio.dev/
COMPOSIO_API_KEY=xxxxxxxxxxxxxxxx

# Optional: Resume Optimizer Pro API (if using their API)
# RESUME_OPTIMIZER_PRO_API_KEY=xxxxxxxxxxxxxxxx
EOF

echo -e "${GREEN}✓${NC} Template created at ~/.env.job-search.template"

# Summary
echo ""
echo "============================================="
echo -e "${GREEN}✅ Installation Complete!${NC}"
echo "============================================="
echo ""
echo "Next steps:"
echo "1. Copy ~/.env.job-search.template to ~/.env and fill in your API keys"
echo "2. Source it: source ~/.env"
echo "3. Restart opencode to load MCP servers"
echo "4. Test with: /job-search --discover --limit 5"
echo ""
echo "Free tier signups:"
echo "  • Firecrawl:     https://www.firecrawl.dev/ (500 credits/mo)"
echo "  • TheirStack:    https://theirstack.com/ (free tier)"
echo "  • Composio:      https://composio.dev/ (free tier)"
echo "  • Resume Optimizer Pro: https://resumeoptimizerpro.com/ (free ATS check)"
echo "  • Teal:          https://www.tealhq.com/ (free unlimited resumes)"
echo "  • HackerRank:    https://www.hackerrank.com/ (free certs)"
echo "  • Interviewing.io: https://interviewing.io/ (free tier mocks)"
echo ""
echo "MCP Servers installed:"
for mcp in "${mcps[@]}"; do
    echo "  • $mcp"
done
echo "  • mcp-server-git (via uvx)"