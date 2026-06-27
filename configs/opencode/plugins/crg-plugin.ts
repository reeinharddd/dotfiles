import type { Plugin } from "@opencode-ai/plugin"

/**
 * code-review-graph plugin for OpenCode.
 *
 * Keeps the knowledge graph up-to-date and surfaces status
 * information automatically during coding sessions.
 */

const CrgPlugin: Plugin = async (ctx) => {
  return {
    // Handle session creation
    event: async ({ event }) => {
      if (event?.type === "session.created") {
        try {
          const result = await ctx.$`code-review-graph status`.quiet()
          const output = result.stdout?.toString().trim()
          if (output) {
            console.log("[code-review-graph]", output)
          }
        } catch {
          // Swallow — not every project has a graph.
        }
      }
    },

    // Handle file edits - auto-update graph
    "file.edited": async ({ $ }) => {
      try {
        await $`code-review-graph update --skip-flows`.quiet()
      } catch {
        // Swallow — graph may not be built yet for this project.
      }
    },

    // Detect changes before git commit commands
    "tool.execute.before": async (ctx) => {
      try {
        const input = ctx?.input ?? ctx?.params ?? {}
        const cmd =
          input.command ?? input.cmd ?? input.content ?? ""
        if (typeof cmd === "string" && /^git\s+commit/i.test(cmd)) {
          const result =
            await ctx.$`code-review-graph detect-changes --brief`.quiet()
          const output = result.stdout?.toString().trim()
          if (output) {
            console.log("[code-review-graph] Pre-commit analysis:\n" + output)
          }
        }
      } catch {
        // Swallow — never block a commit.
      }
    },
  }
}

export default CrgPlugin