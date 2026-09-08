#!/usr/bin/env bash
# auto-extract - Auto-distills large tool outputs using DCP extract concept

set -euo pipefail

TOOL_NAME="${1:-unknown}"
TOOL_OUTPUT=$(cat)

# Only process large outputs (>3000 chars)
if [[ ${#TOOL_OUTPUT} -lt 3000 ]]; then
	echo "$TOOL_OUTPUT"
	exit 0
fi

# Check if DCP extract is available via opencode
if opencode tools list 2>/dev/null | grep -q "extract"; then
	# Mark for agent to run extract
	echo "[AUTO-EXTRACT: Large output from $TOOL_NAME (${#TOOL_OUTPUT} chars). Run 'extract' tool to distill.]"
	echo "$TOOL_OUTPUT" | head -c 1500
	echo ""
	echo "... [extract available - agent will auto-distill]"
else
	# Fallback: truncate with summary
	echo "$TOOL_OUTPUT" | head -c 2000
	echo ""
	echo "... [AUTO-EXTRACTED: Output truncated, ${#TOOL_OUTPUT} chars. Use /dcp-compress to compress.]"
fi
