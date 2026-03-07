# ~/.claude Configuration

## Directory Structure

```
~/.claude/
├── README.md               # This file
├── CLAUDE.md               # Global instructions loaded into every Claude Code session
├── settings.json           # Main configuration (plugins, permissions, statusline, etc.)
├── settings.local.json     # Local overrides (not synced)
├── statusline.sh           # Custom status line script
├── skills/                 # User-defined skills (invoked via /skill-name)
├── plugins/                # Installed plugin cache and metadata
├── projects/               # Per-project auto-memory files
├── plans/                  # Plan files created during plan mode
├── tasks/                  # Task tracking files
├── history.jsonl           # Conversation history
├── skills/                 # Skill definitions
└── cache/                  # Internal cache (telemetry, stats, etc.)
```

## Skills

Custom skills installed in `skills/`:

| Skill | Description |
|-------|-------------|
| `annual-planner` | Generate annual planner PDFs optimised for eink devices (reMarkable, Boox, etc.) |
| `fsm` | Generate Finite State Machine diagrams from natural language (Mermaid / Graphviz) |
| `proxmox-community-script` | Scaffold scripts for the Proxmox VE Community Scripts project |
| `verilog-lint` | Lint and validate Verilog/SystemVerilog using Verilator and Verible |
| `wavedrom` | Generate WaveDrom timing diagrams (WaveJSON) from natural language |

Invoke with `/skill-name` in any Claude Code session.

## Plugins (settings.json)

LSP plugins enabled under `enabledPlugins`. Each requires a language server installed separately:

| Plugin | Install Command |
|--------|----------------|
| `clangd-lsp` | `brew install llvm` |
| `swift-lsp` | Included with Xcode / Swift toolchain |
| `pyright-lsp` | `npm install -g pyright` |
| `skill-creator` | No external dependencies |

## Status Line (statusline.sh)

Custom two-line status bar displayed at the bottom of each session showing:
- Model name, current project directory, git branch
- Context window usage (%), 5-hour token usage (%), 7-day token usage (%), session cost, elapsed time

Usage bars are colour-coded: green < 70%, yellow 70-90%, red >= 90%.
Token usage is fetched from the Anthropic API and cached for 5 minutes in `/tmp/claude-usage-cache.json`.
