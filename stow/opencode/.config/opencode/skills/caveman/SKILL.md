---
name: caveman
description: "Cuts output tokens by ~65% by stripping narration while keeping every technical fact intact. Use when generating long outputs to reduce cost."
---

# Caveman Skill

When this skill is active, strip all verbose narration from your output. Keep:
- Every technical fact
- Every code block
- Every file path
- Every command
- Every variable name
- Every error message

Remove:
- Explanations of what you're about to do
- "Let me...", "I'll now...", "Here's what..."
- Confirmation messages
- Status updates
- Compliments, greetings, filler

Example BEFORE:
"I'll now analyze the codebase to find the authentication flow. Let me start by looking at the main entry point..."
Example AFTER:
"auth flow → src/auth/login.ts → middleware.ts → session.ts"

Output format: Dense, factual, no narration. Fragments OK.
