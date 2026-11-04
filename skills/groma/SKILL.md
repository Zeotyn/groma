---
name: groma
description: Initializes or updates a project for AI-assisted work - detects greenfield/brownfield, interviews, sets up methodology, skills, docs/ and AGENTS.md in eight steps. Use for /groma, "set up this project", "onboard this repo", "initialize project docs", or re-running groma on an initialized project.
---

# groma

Lay out a project before building on it. Eight steps, each announced, each safe to re-run.

**Writes are additive.** groma creates files only at paths that do not exist, plus its own `.groma/` and `docs/_groma/`. Anything that would change an existing file becomes a snippet in the findings report. Third-party installers run only after the user agreed when they touch existing files.

Sibling skills live next to this folder (`../groma-detect/`, `../groma-survey/`, ...). Run a step by following that skill's `SKILL.md`. If a sibling is missing, skip its step and print its install command:
`npx skills add Zeotyn/groma --skill <name>`.

## Mode

- `<project>/.groma/config.yaml` absent: **init mode**, all steps.
- Present: run `sh scripts/validate-config.sh <project>/.groma/config.yaml --catalog ../groma-skills/catalog.yaml` (drop `--catalog` if groma-skills is missing). Exit 3: stop and print the update command. Errors: show them with line numbers and ask the user to fix or let you reconfigure. Valid: **update mode**: resume at the first step whose `steps.<name>` is `pending`; when all are `done`, run steps 6 to 8 again (missing docs, freshness, summary) and offer to reconfigure skills or agents. Compare `initialized_with` with [VERSION](VERSION) and apply the rows of [references/upgrades.md](references/upgrades.md) in between, naming the version that introduced each addition.

## Steps

Announce each step as `Step N of 8: <name>, <what it does>`. After each step set `steps.<name>` in the config (`done`, `pending` or `skipped`), once the config exists.

1. **detect**: follow `../groma-detect/SKILL.md`. Result: project type and evidence.

2. **interview**: ask only what the folder does not answer, one question at a time, recommended option first:
   - greenfield: what is being built and for whom (feeds vision and concept), does it have a UI, which agents (claude, copilot, gemini, cursor, codex).
   - brownfield: confirm the project purpose in one sentence from README and code, ask about UI only when no frontend is visible, ask about agents only when no agent folders exist.
   Done when name, purpose, `has_ui` and `agents` are known.

3. **config**: create `<project>/.groma/config.yaml` from [templates/config.yaml](templates/config.yaml) (it carries the `review` and `reminders` defaults: autonomous loop, reviewer auto) with the answers so far (methodology and skills stay as placeholders filled by steps 4 and 5; write `none` where still unknown), `initialized_with: groma@<VERSION>`. Run `sh scripts/check-prereqs.sh` and report missing required tools with their install hint.

4. **methodology**: follow `../groma-methodology/SKILL.md`.

5. **skills**: follow `../groma-skills/SKILL.md`.

6. **docs**:
   - brownfield: follow `../groma-survey/SKILL.md` first, then `../groma-lay-out/SKILL.md` with the survey results.
   - greenfield: follow `../groma-lay-out/SKILL.md` with the interview answers.

7. **agents**: follow `../groma-agents/SKILL.md`.

8. **summary**: print
   ```
   groma <VERSION> · <project type> · step 8 of 8 done

   Created:   <files, grouped by folder>
   Untouched: <existing files that got a snippet in docs/_groma/findings-*.md>
   Findings:  <n high> high · <n medium> medium · <n low> low   → docs/_groma/findings-<date>.md
   Pending:   <commands in .groma/install.sh, or "none">

   Next: <one concrete action, e.g. "Review docs/adr/0003-use-postgresql.md (proposed)",
          or when nothing is open: "Start your first change with groma-loop">
   ```
   Done when the summary names exactly one next action.

## Rules for every step

- Ask at most one question per message, with a recommended default.
- Unknown content is written as `Not yet documented.`, never guessed.
- An aborted run leaves valid files; the next run resumes from `steps`.
