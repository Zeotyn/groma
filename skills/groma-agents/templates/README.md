# Agent instruction templates

| Template | Target path | Agent |
|---|---|---|
| `AGENTS.md` | `AGENTS.md` | all (canonical) |
| `CLAUDE.md` | `CLAUDE.md` | Claude Code |
| `GEMINI.md` | `GEMINI.md` | Gemini CLI |
| `copilot-instructions.md` | `.github/copilot-instructions.md` | GitHub Copilot |
| `groma.mdc` | `.cursor/rules/groma.mdc` | Cursor |
| `claude-session-hook.json` | `.claude/settings.local.json` (optional, only on request) | Claude Code |
| `claude-stop-hook.json` | `.claude/settings.local.json` (optional, only on request) | Claude Code |
| `statusline-snippet.sh` | none, printed as a snippet in the findings report and summary | Claude Code |
| `statusline-pill.sh` | none, its last line is printed as a snippet in the findings report and summary | Claude Code |

Codex reads `AGENTS.md` directly and needs no pointer file.
