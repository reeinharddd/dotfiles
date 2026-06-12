# systemInfo — Central Knowledge Base

System-wide hardware, software, and configuration knowledge base.
Exposed via MCP for AI agents to consume in real-time.

## Structure

```
systemInfo/
├── hardware/
│   └── current.json      Live hardware specs (CPU, RAM, disk, GPU)
├── software/
│   └── current.json      Installed tools with versions
├── configs/              Dotfiles and app configurations
├── projects/
│   └── registry.json     Project registry (path, language, version)
├── scripts/
│   └── scan.sh           Regenerate all data files
└── mcp-server/
    └── run.py            MCP server (exposes data via stdin/stdout)
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
bash ~/systemInfo/scripts/scan.sh

# Query via MCP
echo '{"tool":"system_info","args":{}}' | python3 ~/systemInfo/mcp-server/run.py

# Browse data
cat ~/systemInfo/hardware/current.json | python3 -m json.tool
cat ~/systemInfo/software/current.json | python3 -m json.tool
cat ~/systemInfo/projects/registry.json | python3 -m json.tool
```
