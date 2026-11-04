---
name: groma-agents
description: Writes one canonical AGENTS.md and pointer files for Claude Code, Copilot, Gemini CLI and Cursor so every agent reads the same project instructions. Use during /groma or when agent instruction files are missing or out of sync.
---

# groma-agents

One source of instructions: `AGENTS.md`. Every other agent file only points to it.

**Writes are additive.** Create a file only when its path does not exist. For an existing file, put the suggested line into the findings report.

## Steps

1. **AGENTS.md.** If `<project>/AGENTS.md` is absent, fill [templates/AGENTS.md](templates/AGENTS.md):
   - commands: read them from the environment (`package.json` scripts, `Makefile`, `pyproject.toml`, `pom.xml`, `go.mod`, CI workflow); exact commands only, `Not yet documented.` when none exist.
   - methodology, workflow and skills: from `.groma/config.yaml`; `methodology_hint` is one sentence on where changes live (for example "Changes live in openspec/changes/; use /opsx:propose").
   - change naming: the rule text from `../groma-methodology/references/conventions.md` when available, else the template text with the config's types.
   Keep it under 150 lines. Done when no `{{` remains.

2. **Pointer files.** For each agent in `agents`, create the file from [templates/](templates/README.md) when absent:

   | Agent | File | Template |
   |---|---|---|
   | claude | `CLAUDE.md` | `templates/CLAUDE.md` |
   | gemini | `GEMINI.md` | `templates/GEMINI.md` |
   | copilot | `.github/copilot-instructions.md` | `templates/copilot-instructions.md` |
   | cursor | `.cursor/rules/groma.mdc` | `templates/groma.mdc` |
   | codex | none, reads AGENTS.md | - |

3. **Existing files.** For each existing agent file that does not mention `AGENTS.md`, add a snippet to the findings report: for `CLAUDE.md`/`GEMINI.md` the line `@AGENTS.md`, for Copilot and Cursor the sentence from the template. Existing `AGENTS.md` without a link to `docs/README.md`: suggest the "Read first" section.

4. **Report.** Files created, files left untouched with their snippet.
