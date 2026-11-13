# cli Specification

## Purpose
Gives users one command, `npx groma-cli init`, that sets up a project deterministically without an agent: groma skills in every agent's project folder, the chosen methodology, the chosen catalog skills and the project config, plus `update`, `status` and `doctor` for the rest of the project's life.
## Requirements
### Requirement: Commands
The `groma` CLI SHALL provide `init [path]`, `update [path]`, `status [path]` and `doctor [path]`, plus `--help` and `--version`. `[path]` defaults to the current directory.

#### Scenario: Help
- **WHEN** the user runs `npx groma-cli --help`
- **THEN** the four commands and their main flags are listed

### Requirement: Interactive and non-interactive init
`groma init` SHALL ask, one question at a time with the recommended option preselected, for: agents, methodology, workflow layer, catalog skills per category (respecting conditions and single/multi select), and review mode. Each question SHALL be answerable by a flag: `--agents <list|all|none>`, `--methodology <id>`, `--workflow <id>`, `--skills <recommended|none|id,...>`, `--review <autonomous|gated>`, `--ui <yes|no>`. `--yes` SHALL take the recommended option for every question not given by a flag. Without a TTY, missing answers SHALL fall back to `--yes` behavior and say so.

#### Scenario: Fully non-interactive
- **WHEN** the user runs `npx groma-cli init --agents claude,copilot --methodology openspec --skills recommended --yes`
- **THEN** no question is asked, and the result equals choosing those answers interactively

#### Scenario: Agents detected
- **WHEN** `--agents` is not given and the machine has `~/.claude` and `~/.copilot`
- **THEN** the agents question preselects claude and copilot

### Requirement: Skill materialization
`groma init` SHALL copy every groma skill folder unchanged (SKILL.md, scripts, templates, references) into the project skill folder of each selected agent, and SHALL add `metadata.generatedBy: groma@<version>` to each copied SKILL.md. It SHALL record every generated file with its SHA-256 in `.groma/generated.json`.

#### Scenario: Claude and Copilot
- **WHEN** init runs with agents claude and copilot
- **THEN** `.claude/skills/groma/SKILL.md` and `.github/skills/groma/SKILL.md` exist with `generatedBy: groma@<version>`, together with all other groma skills and their scripts

#### Scenario: Foreign skill with the same name
- **WHEN** `.claude/skills/groma-survey/` exists and is not listed in `.groma/generated.json`
- **THEN** init does not touch it, reports a conflict, and continues with the other skills

### Requirement: Deterministic setup steps
`groma init` SHALL run the methodology init and the catalog installs from the shared recipe data, write `.groma/config.yaml` from the template with every answer, and set `steps.config`, `steps.methodology` and `steps.skills` to `done`, or to `pending` when a step could not run. It SHALL follow the same rules as the skills: never pass overwrite flags, ask before an installer touches an existing file (`--yes` answers no and records the command in `.groma/install.sh`), and never modify other pre-existing files.

#### Scenario: Methodology already present
- **WHEN** `openspec/` exists
- **THEN** init does not run `openspec init`, records `methodology: openspec` and marks the step done

#### Scenario: Installer would touch an existing file under --yes
- **WHEN** `skills-lock.json` exists and init runs with `--yes`
- **THEN** the `npx skills` command is written to `.groma/install.sh`, `steps.skills` is `pending`, and the summary says why

### Requirement: Dry run and print
`--dry-run` SHALL print every file and command init would write or run and change nothing. `--print` SHALL write the commands to `.groma/install.sh` instead of running them, and still materialize skills and write the config.

#### Scenario: Dry run
- **WHEN** the user runs `npx groma-cli init --dry-run --yes`
- **THEN** the planned files and commands are printed, and the project is byte-identical afterwards

### Requirement: Hand-off to the agent
After init the CLI SHALL print a summary (agents, methodology, skills installed or pending, files created) and one next action: open the project in the agent and run `/groma`.

#### Scenario: Summary
- **WHEN** init finishes
- **THEN** the last line names `/groma` as the next action

### Requirement: Update
`groma update` SHALL refresh every generated file to the CLI's version: unchanged copies (hash equals `.groma/generated.json`) are replaced, edited copies are kept and reported unless `--force` is given. An unchanged file SHALL be deleted only when groma no longer ships it: the file left a shipped skill, or its skill is listed in `skills/groma/retired-skills.txt`; copies of any other skill are kept. `groma update` and `groma init` SHALL stop with an error, unless `--allow-downgrade` is given, when `.groma/generated.json` was written by a newer groma (`--force` alone does not allow it), SHALL treat a symbolic link at or above a destination path and a skills folder that leads out of the project as conflicts, SHALL record every written file in `.groma/generated.json` even when the run is interrupted, and SHALL make no copies when `steps.skills_copy` is `skipped` and no `.groma/generated.json` exists. It SHALL then re-run pending steps and bump `initialized_with`.

#### Scenario: User edited a generated skill
- **WHEN** the user changed `.claude/skills/groma-survey/SKILL.md` and runs `groma update`
- **THEN** that file is kept, reported as "edited, not updated", and replaced only with `--force`

#### Scenario: Older CLI, newer project
- **WHEN** `.groma/generated.json` names a newer `generatedBy` than the CLI and the user runs `groma update`
- **THEN** the command exits with an error, changes nothing and names `--allow-downgrade`, also when `--force` is given

#### Scenario: Declined copy
- **WHEN** `steps.skills_copy` is `skipped`, no `.groma/generated.json` exists and the user runs `groma update`
- **THEN** no skill folder is written

### Requirement: Duplicate plugin detection
When the Claude Code plugin `groma` is installed, `groma init` SHALL still copy the skills for Claude by default, because the project copy is what the team gets, and SHALL print how to switch the plugin off for this project. When the user chooses to skip, no files are written to `.claude/skills/groma*` and the config records `agents_via_plugin: [claude]`.

#### Scenario: Plugin present, default
- **WHEN** `claude plugin list` shows `groma` and the user accepts the default
- **THEN** the Claude skill copies are written and the output says how to switch the plugin off for this project

#### Scenario: Plugin present
- **WHEN** `claude plugin list` shows `groma` and the user chooses skip
- **THEN** no files are written to `.claude/skills/groma*`, and the config records `agents_via_plugin: [claude]`

### Requirement: Status and doctor
`groma status` SHALL print the lifecycle reminders (same output as `status.sh`). `groma doctor` SHALL check prerequisites, validate `.groma/config.yaml` against the catalog, and compare generated files with `.groma/generated.json`, exiting non-zero on errors.

#### Scenario: Doctor finds an edited generated file
- **WHEN** a generated SKILL.md was changed
- **THEN** doctor reports it as a warning with the path, and exits 0 if nothing else is wrong

### Requirement: Exit codes
The CLI SHALL exit 0 on success, 1 on errors, 2 on usage errors and 3 when prerequisites are missing; `init` with pending steps exits 0 and lists them.

#### Scenario: Node too old
- **WHEN** `groma init` runs on Node 20
- **THEN** it exits 3 with "Node 22 or newer required"

### Requirement: Next command
`groma next [path]` SHALL run the next-action script with `--long` by default and pass `--short` and `--json` through, with exit code 0 also when nothing is printed.

#### Scenario: Terminal use
- **WHEN** the user runs `npx groma-cli next` in a project with 3 unpushed commits
- **THEN** it prints "Push 3 commits on main: git push"

