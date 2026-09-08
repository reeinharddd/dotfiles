#!/usr/bin/env bash
# Pre-compaction save hook - saves session summary to engram before compaction
# Triggered by OMO preemptive-compaction hook or DCP compress tool

set -euo pipefail

PROJECT="${OPENCODE_PROJECT:-$(basename "$PWD")}"
SESSION_ID="${OPENCODE_SESSION_ID:-manual-$(date +%s)}"

log_info() { echo "[pre-compaction-save] $*" >&2; }

# Generate structured session summary
generate_summary() {
	cat <<EOF
## Goal
[Auto-captured before compaction] Continue previous work on $PROJECT

## Instructions
- Spanish for chat, English for code/docs
- Tools: opencode (TUI), no IDE plugins
- Keyboard-first, no mouse
- Plan before build for tasks >3 files
- Save decisions with engram mem_save

## Discoveries
- Pre-compaction save preserves critical context
- Engram topic_key enables evolving observations
- Protected tags + turn protection = layered defense

## Accomplished
- Implemented pre-compaction engram save hook
- Auto-wrap valuable outputs in <protect> tags
- Extract tool auto-distillation for large outputs

## Next Steps
- Monitor compaction frequency via /dcp stats
- Tune modelMaxLimits per actual usage

## Relevant Files
- ~/.config/opencode/dcp.jsonc — DCP config (disabled, OMO handles)
- ~/.config/opencode/oh-my-openagent.json — OMO config with DCP enabled
- ~/.config/opencode/opencode.jsonc — OpenCode native compaction + tool_output limits
EOF
}

# Main: save to engram
main() {
	log_info "Saving pre-compaction session summary for $PROJECT"

	# Save structured session summary
	engram mem_session_summary \
		--session-id "$SESSION_ID" \
		--content "$(generate_summary)" \
		2>/dev/null || log_info "engarm mem_session_summary failed (ok if first run)"

	# Save pattern observation for evolving knowledge
	engram mem_save \
		--title "Pre-compaction auto-save pattern" \
		--type "pattern" \
		--topic_key "pattern/pre-compaction-save" \
		--content "**What**: Auto-saved session summary before context compaction
**Why**: Preserve critical context that compaction would lose
**Where**: engram session summary + pattern observation
**Learned**: Engram mem_session_summary captures structured context; topic_key allows evolution" \
		--scope project \
		--project "$PROJECT" 2>/dev/null || log_info "engarm mem_save failed (ok if first run)"

	log_info "Pre-compaction save complete"
}

main "$@"
