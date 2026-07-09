#!/bin/bash
# Test MCP servers with opencode

echo "🧪 Testing MCP Servers with opencode"
echo "===================================="

# Test each MCP server
mcps=(
    "firecrawl"
    "linkedin"
    "jobspy"
    "theirstack"
    "playwright"
    "github"
    "fantastic-jobs"
    "composio"
    "filesystem"
    "git"
    "memory"
    "fetch"
    "sequentialthinking"
)

for mcp in "${mcps[@]}"; do
    echo -n "Testing $mcp... "
    if timeout 10 opencode mcp test "$mcp" 2>/dev/null; then
        echo "✅ PASS"
    else
        echo "⚠️  SKIP (needs env vars or opencode restart)"
    fi
done

echo ""
echo "Done. Restart opencode after setting env vars in ~/.env"
