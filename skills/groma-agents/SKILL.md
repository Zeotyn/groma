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
   - `status_script`: the path of `../groma-methodology/scripts/status.sh` as the project's agents will reach it (relative to the project when the skill is installed project-locally, else the installed path). groma-methodology missing: drop the "Session start" section.
   - `review_mode`: `review.mode` from the config (default `autonomous`). groma-loop not installed: drop that bullet.
   - `docs_impact_script`: the path of `../groma-lay-out/scripts/docs-impact.sh`, resolved like `status_script`. `docs.gate: off` or groma-lay-out missing: drop the "Living docs" bullet.
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

4. **Session hook (Claude Code, optional).** When `claude` is in `agents`, ask once: "Run the groma status reminder automatically at every Claude Code session start?" On yes, write [templates/claude-session-hook.json](templates/claude-session-hook.json) with the absolute path of `status.sh` to `<project>/.claude/settings.local.json` (machine-specific, not committed). If that file already exists, show the `hooks` block and add it only after the user approves that edit; otherwise put it into the findings report as a snippet. On no, change nothing; the AGENTS.md line remains the reminder.

5. **Report.** Files created, files left untouched with their snippet, hook installed or declined.
