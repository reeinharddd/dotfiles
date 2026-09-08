#!/usr/bin/env bash
# auto-protect-wrap - Auto-wraps high-value tool outputs in <protect> tags

set -euo pipefail

# Read tool name from first arg, output from stdin
TOOL_NAME="${1:-unknown}"
TOOL_OUTPUT=$(cat)

# Tools whose outputs should be auto-protected
PROTECTED_TOOLS=(
	"codegraph_explore"
	"codegraph_node"
	"codegraph_search"
	"codegraph_callers"
	"task"
	"skill"
	"grep_app_searchGitHub"
	"firecrawl_firecrawl_scrape"
	"firecrawl_firecrawl_search"
	"context7_query-docs"
	"engram_mem_search"
	"engram_mem_context"
)

should_protect=false
for tool in "${PROTECTED_TOOLS[@]}"; do
	if [[ "$TOOL_NAME" == "$tool" ]]; then
		should_protect=true
		break
	fi
done

# Also protect large outputs (>5000 chars)
if [[ ${#TOOL_OUTPUT} -gt 5000 ]]; then
	should_protect=true
fi

if [[ "$should_protect" == true ]]; then
	echo "<protect>"
	echo "$TOOL_OUTPUT"
	echo "</protect>"
else
	echo "$TOOL_OUTPUT"
fi
