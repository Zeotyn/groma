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
   - `status_script`: the path of `../groma-methodology/scripts/status.sh` as the project's agents will reach it (relative to the project when the skill is installed project-locally, else the installed path). groma-methodology missing: drop the "Session start" and "Session end" sections.
   - `next_script`: the path of `../groma-methodology/scripts/next.sh`, resolved like `status_script`.
   - `review_mode`: `review.mode` from the config (default `autonomous`). groma-loop not installed: drop that bullet.
   - `docs_impact_script`: the path of `../groma-lay-out/scripts/docs-impact.sh`, resolved like `status_script`. `docs.gate: off` or groma-lay-out missing: drop the "Living docs" bullet.
   - `code_style_doc`: the file that fills the code-style slot (`docs/code-style.md`, or the style guide the docs index links for it). `style_checks`: the check commands from that doc's "Enforced by tools" table, one per line; no tool: `None configured.`. Do not copy conventions into AGENTS.md; the pointer is enough.
   - "Git workflow" section, from the `git` keys of the config (missing keys: `integrate: rebase`, `branch_per_change: true`, `commits: conventional`, `push: ask`). `main_branch`: the "Main branch" rule of [references/git-strategies.md](references/git-strategies.md) (the remote's default branch, else `main`, else `master`, else `main`). `git_integrate` and `git_abort`: the Commands and On conflict cells of the configured strategy's row in that table, with `<main>` resolved and `<branch>` and `<message file>` kept. `commits_rule`: `conventional` → "Conventional Commits, `<type>(<change-id>): <summary>`"; `free` → "free subjects". `push_rule`: `ask` → "push `<main>` only when the user agreed"; `auto` → "push `<main>` after every integration"; `never` → "never push, the user pushes". `branch_per_change: false`: replace the branch bullet with "Work on `<main>` directly; groma-loop creates no branches." Not a git repository: drop the section.
   Keep it under 150 lines. Done when no `{{` remains.

2. **Pointer files.** For each agent in `agents`, create the file from [templates/](templates/README.md) when absent:

   | Agent | File | Template |
   |---|---|---|
   | claude | `CLAUDE.md` | `templates/CLAUDE.md` |
   | gemini | `GEMINI.md` | `templates/GEMINI.md` |
   | copilot | `.github/copilot-instructions.md` | `templates/copilot-instructions.md` |
   | cursor | `.cursor/rules/groma.mdc` | `templates/groma.mdc` |
   | codex | none, reads AGENTS.md | - |

3. **Existing files.** For each existing agent file that does not mention `AGENTS.md`, add a snippet to the findings report: for `CLAUDE.md`/`GEMINI.md` the line `@AGENTS.md`, for Copilot and Cursor the sentence from the template. Existing `AGENTS.md` without a link to `docs/README.md`: suggest the "Read first" section. Existing `AGENTS.md` without a "Git workflow" section (in a git repository): put the section of the template, rendered as in step 1, into the findings report as a snippet; an existing file is never edited, not even one groma wrote in an earlier run.

4. **Session hook (Claude Code, optional).** When `claude` is in `agents`, ask once: "Run the groma status reminder automatically at every Claude Code session start?" On yes, fill [templates/claude-session-hook.json](templates/claude-session-hook.json) with the absolute path of `status.sh`; it goes to `<project>/.claude/settings.local.json` (machine-specific, not committed), written once after step 5 so that both hooks land in the same new file. If that file already exists, show the `hooks` block and add it only after the user approves that edit; otherwise put it into the findings report as a snippet. On no, change nothing; the AGENTS.md line remains the reminder.

5. **Next action (optional).** Hook support per agent is the `hook` entry in [../groma/agents.yaml](../groma/agents.yaml). When `claude` is in `agents`, ask once: "Show groma's next action after each answer (Stop hook) and in your status line? (yes = both, or name one)" Never offer this again in a later run unless the user asks.
   - **Yes, Stop hook:** fill [templates/claude-stop-hook.json](templates/claude-stop-hook.json) with the absolute path of `../groma-methodology/scripts/next-stop.sh`. `<project>/.claude/settings.local.json` absent before this run: create it with one `hooks` object holding every hook accepted in steps 4 and 5. Present: put the `hooks` block into the findings report as a snippet. When groma created the file and `git check-ignore -q .claude/settings.local.json` fails, put the `.gitignore` line `.claude/settings.local.json` into the findings report and the summary: until it is ignored, `next.sh` counts the file as uncommitted work. Set `next.hook: on` in `.groma/config.yaml`; the hook prints nothing while it is `off`.
   - **Yes, status line:** never edit a status line setting or script, wherever it lives. Put both forms of [templates/statusline-snippet.sh](templates/statusline-snippet.sh), with `{{next_script_absolute}}` resolved, into the findings report and the summary: the one line to add to an existing status line script, and the standalone script with the `statusLine` setting that runs it.
   - **No:** change nothing; the AGENTS.md "Session end" line and `npx groma-cli next` remain.
   - **Other agents:** offer a hook only for agents whose `hook.status` is `stable`. When the user asks for an `experimental` one, warn first: it is untested in that CLI's interactive mode and could behave differently there, up to starting another agent turn. After the user confirms, put its `event`, `config` and `format` with the `next-stop.sh` command into the findings report as a snippet (`stderr-exit2`: `next-stop.sh --stderr`); groma writes no hook file for these agents. `none`: no hook; the AGENTS.md line is the only mechanism.

6. **Report.** Files created, files left untouched with their snippet, hooks installed or declined, the status-line snippet.
