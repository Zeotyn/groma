---
name: groma
description: Initializes or updates a project for AI-assisted work - methodology, skills, docs/ and AGENTS.md. Use for /groma, "set up this project", "onboard this repo", "initialize project docs", or re-running groma on an initialized project.
---

# groma

Lay out a project before building on it. Eight steps, each announced, each safe to re-run.

**Writes are additive.** groma creates files only at paths that do not exist, plus its own `.groma/` and `docs/_groma/`. Anything that would change an existing file becomes a snippet in the findings report. Third-party installers run only after the user agreed when they touch existing files.

Sibling skills live next to this folder (`../groma-detect/`, `../groma-survey/`, ...). Run a step by following that skill's `SKILL.md`. If a sibling is missing, skip its step and print its install command:
`npx skills add Zeotyn/groma --skill <name>`.

## Mode

- `<project>/.groma/config.yaml` absent: **init mode**, all steps.
- Present: run `sh scripts/validate-config.sh <project>/.groma/config.yaml --catalog catalog.yaml` ([catalog.yaml](catalog.yaml) is a copy of groma-skills' catalog). Exit 3: stop and print the update command. Errors: show them with line numbers and ask the user to fix or let you reconfigure. Valid: **update mode**: resume at the first step whose `steps.<name>` is `pending`; when all are `done`, run steps 6 to 8 again (missing docs, freshness, summary) and offer to reconfigure skills or agents. Compare `initialized_with` with [VERSION](VERSION) and apply the rows of [references/upgrades.md](references/upgrades.md) in between, naming the version that introduced each addition. Refresh the copied groma skills yourself, see "Skill copies"; this needs no CLI.

**CLI hand-off.** `npx groma-cli init` may already have done the config, methodology and skills steps. When `steps.config`, `steps.methodology` and `steps.skills` are all `done`, do not repeat them or ask their questions (agents, methodology, skills); go on with detect, the content interview (purpose, users, vision, UI only if unknown), docs and agents. When `steps.methodology` or `steps.skills` is `pending`, third-party installs are still open: offer once to run them now (steps 4 and 5 with their consent flow) and name `npx groma-cli update` in a terminal as the alternative. Without a yes, install nothing, leave the step `pending` and make the summary's Next action "Run `npx groma-cli update` in a terminal". Copying and refreshing the groma skills never needs the CLI ("Skill copies"). Agents listed in `agents_via_plugin` are agents for which the user declined the copy in the CLI: they get their skills from the plugin, and no copies are made for them.

## Steps

Announce each step as `Step N of 8: <name>, <what it does>`. After each step set `steps.<name>` in the config (`done`, `pending` or `skipped`), once the config exists.

1. **detect**: follow `../groma-detect/SKILL.md`. Result: project type and evidence.

2. **interview**: ask only what the folder does not answer, one question at a time, recommended option first:
   - greenfield: what is being built and for whom (feeds vision and concept), does it have a UI, the main language or stack, which agents (claude, copilot, gemini, cursor, codex).
   - brownfield: confirm the project purpose in one sentence from README and code, ask about UI only when no frontend is visible, ask about agents only when no agent folders exist.
   - style tools: run `sh scripts/style-drift.sh <project>` (read-only). When it prints a `tool` line, ask nothing. Otherwise look up the stack's default tools in [references/code-style-tools.md](references/code-style-tools.md) (the rows with `Default: yes` for the stack, plus every row with stack `all`, so EditorConfig is always in the set) and ask once, for example "Set up EditorConfig and Ruff for formatting and linting? (recommended)". Brownfield: the recommended option is "document only"; the tools are the second option. Record the answer as the chosen tools, `document only` or `none`.
   - git workflow: in a git repository (`git -C <project> rev-parse --is-inside-work-tree`), run `sh scripts/git-practice.sh <project>` (read-only) and ask once for the integration strategy (`rebase`, `merge`, `squash`) and once for the push policy (`ask`, `auto`, `never`). Greenfield: recommend `rebase` and `push: ask`. Brownfield: recommend the script's `integrate` value and show its evidence, for example "Integrate changes with merge commits? (recommended: 28 of 30 merges are pull-request merges)", and recommend `push: ask`. Take `commits` from the script's `commits` line without asking (greenfield: `conventional`). Outside git: ask nothing and keep the defaults. Record `integrate`, `commits` and `push`.
   Done when name, purpose, `has_ui`, `agents`, the style answer and the git answers are known.

3. **config**: create `<project>/.groma/config.yaml` from [templates/config.yaml](templates/config.yaml) (it carries the `review` and `reminders` defaults: autonomous loop, reviewer auto) with the answers so far (methodology and skills stay as placeholders filled by steps 4 and 5; write `none` where still unknown; `git.integrate`, `git.commits` and `git.push` from the interview, the template's defaults when it asked nothing), `initialized_with: groma@<VERSION>`. Run `sh scripts/check-prereqs.sh` and report missing required tools with their install hint.

4. **methodology**: follow `../groma-methodology/SKILL.md`. When the CLI already ran the methodology init, still run that skill's step 4 (Convention: conventions baseline and check-conventions) if not done.

5. **skills**: follow `../groma-skills/SKILL.md`.

6. **docs**:
   - brownfield: follow `../groma-survey/SKILL.md` first, then `../groma-lay-out/SKILL.md` with the survey results.
   - greenfield: follow `../groma-lay-out/SKILL.md` with the interview answers.
   When the interview chose style tools, groma-lay-out's "Style setup" runs first: config files at free paths, one accepted ADR per tool, installs through the consent flow (`.groma/install.sh` when declined). "document only" and "none" create no config and no ADR; the doc records the decision. Update mode never creates tool configs unless the user asks.

7. **agents**: follow `../groma-agents/SKILL.md`, then do "Skill copies" below.
   Done when the agent files exist and `steps.skills_copy` is `done` or `skipped`.

8. **summary**: print
   ```
   groma <VERSION> · <project type> · step 8 of 8 done

   Created:   <files, grouped by folder>
   Untouched: <existing files that got a snippet in docs/_groma/findings-*.md>
   Findings:  <n high> high · <n medium> medium · <n low> low   → docs/_groma/findings-<date>.md
   Skills:    <n groma skill files copied for <agents>, or "not copied (declined)">
   Plugin:    <only after a `plugin` line: the reason and the disable command, see "Skill copies">
   Pending:   <commands in .groma/install.sh, or "none">

   Next: <one concrete action, e.g. "Review docs/adr/0003-use-postgresql.md (proposed)",
          or when nothing is open: "Start your first change with groma-loop">
   ```
   Done when the summary names exactly one next action.

## Skill copies

The groma skills belong into the project, so a teammate who clones the repository gets them. [scripts/materialize.sh](scripts/materialize.sh) copies the groma skill folders installed next to this one into each agent's project skill folder, with the rules of `npx groma-cli init`: copied `SKILL.md` files carry `metadata.generatedBy: groma@<version>`, every file is recorded with its SHA-256 in `.groma/generated.json`, and a file or folder groma did not create is never touched. Never copy or edit skill files yourself; when the script fails (for example neither `sha256sum` nor `shasum` exists), report its message and leave `steps.skills_copy: pending`.

- **Init, in step 7.** When `steps.skills_copy` is `done` or `skipped` (set by `npx groma-cli init` or an earlier run), ask nothing. Otherwise ask once, in the user's language, with yes recommended: "Put the groma skills into the project so the team gets them with the repository?"
  - Yes: run `sh scripts/materialize.sh --agents <agents, comma-separated> <project>` and set `steps.skills_copy: done`.
  - No: write no skill folder and set `steps.skills_copy: skipped`.
- **Update mode.** When `steps.skills_copy` is `done`, or the key is missing and `.groma/generated.json` exists, run `sh scripts/materialize.sh --update <project>` (agents come from the config, without `agents_via_plugin`) before step 6. Unchanged copies move to the new version, files of removed skills are deleted only when unchanged. When the key is missing and no `.groma/generated.json` exists, ask the init question once. `skipped`: do nothing.
- **Output.** `create`, `update` and `remove` lines are done work; count them for the summary. For each `edited` line tell the user the file was edited by hand and kept (`--force` replaces it; use it only when the user asks). For each `conflict` line tell the user the path was not created by groma and was left untouched. `--dry-run` shows the plan without writing.
- **Plugin.** A line `plugin<TAB>claude<TAB><command>` means the groma Claude Code plugin is active as well. The copy is made all the same, because it is what the team gets. Tell the user in their language: Claude Code now lists every groma skill twice in this project, once from the plugin and once from the project copy, and the command `claude plugin disable groma@groma --scope local`, run in the project, switches the plugin off for this project only (it stays on everywhere else). Print the command unchanged. Never run it and never edit a settings file. Repeat the command once in the summary.

## Rules for every step

- Ask at most one question per message, with a recommended default.
- Unknown content is written as `Not yet documented.`, never guessed.
- An aborted run leaves valid files; the next run resumes from `steps`.
