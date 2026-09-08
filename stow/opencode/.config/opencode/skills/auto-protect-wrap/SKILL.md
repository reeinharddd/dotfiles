---
name: auto-protect-wrap
version: "1.0.0"
description: "Auto-wraps high-value tool outputs in <protect> tags for DCP compression preservation"
author: reeinharrrd
license: MIT
compatibility: ">= 3.0.0"
---

# Auto-Protect Wrap Skill

Automatically wraps outputs from high-value tools in `<protect>...</protect>` tags so DCP compression preserves them.

## Protected Tools

- `codegraph_explore`, `codegraph_node`, `codegraph_search`, `codegraph_callers`
- `task`, `skill`
- `grep_app_searchGitHub`, `firecrawl_firecrawl_scrape`, `firecrawl_firecrawl_search`
- `context7_query-docs`
- `engram_mem_search`, `engram_mem_context`
- Any output >5000 characters

## Usage

Triggered automatically via OMO hook `auto_protect_wrap`.

```bash
# Manual test
echo "large output..." | auto-protect-wrap codegraph_explore
```

## Integration

```json
{
  "hooks": {
    "auto_protect_wrap": {
      "enabled": true,
      "command": "auto-protect-wrap"
    }
  }
}
```