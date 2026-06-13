# dotfiles / systemInfo — Central Knowledge Base

System-wide hardware, software, and configuration knowledge base.
Exposed via MCP for AI agents to consume in real-time.

Canonical location: `~/projects/dotfiles`
Legacy symlink: `~/systemInfo` → `~/projects/dotfiles`

## Structure

```
dotfiles/
├── hardware/
│   └── current.json      Live hardware specs (CPU, RAM, disk, GPU)
├── software/
│   └── current.json      Installed tools with versions
├── configs/              Dotfiles and app configurations
├── projects/
│   └── registry.json     Project registry (path, language, version)
├── scripts/
│   └── scan.sh           Regenerate all data files
├── mcp-server/
│   └── run.py            MCP server (exposes data via stdin/stdout)
├── SPEC.md               System Context Universal specification
└── CONTEXT.md            Generated agent context
```

## MCP Tools

| Tool | Description |
|------|-------------|
| `system_info` | Full hardware + software snapshot |
| `list_tools` | Installed dev tools (optionally by category) |
| `list_projects` | Project registry |
| `scan` | Regenerate all cached data files |

## Usage

```bash
# Rescan all data
bash scripts/scan.sh

# Query via MCP
echo '{"tool":"system_info","args":{}}' | python3 mcp-server/run.py

# Browse data
cat hardware/current.json | python3 -m json.tool
cat software/current.json | python3 -m json.tool
cat projects/registry.json | python3 -m json.tool
```
