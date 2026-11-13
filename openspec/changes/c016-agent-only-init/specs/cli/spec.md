## MODIFIED Requirements

### Requirement: Duplicate plugin detection
When the Claude Code plugin `groma` is installed, `groma init` SHALL still copy the skills for Claude by default, because the project copy is what the team gets, and SHALL print how to switch the plugin off for this project. When the user chooses to skip, no files are written to `.claude/skills/groma*` and the config records `agents_via_plugin: [claude]`.

#### Scenario: Plugin present, default
- **WHEN** `claude plugin list` shows `groma` and the user accepts the default
- **THEN** the Claude skill copies are written and the output says how to switch the plugin off for this project

#### Scenario: Plugin present
- **WHEN** `claude plugin list` shows `groma` and the user chooses skip
- **THEN** no files are written to `.claude/skills/groma*`, and the config records `agents_via_plugin: [claude]`

### Requirement: Update
`groma update` SHALL refresh every generated file to the CLI's version: unchanged copies (hash equals `.groma/generated.json`) are replaced, edited copies are kept and reported unless `--force` is given. An unchanged file SHALL be deleted only when groma no longer ships it: the file left a shipped skill, or its skill is listed in `skills/groma/retired-skills.txt`; copies of any other skill are kept. `groma update` SHALL stop with an error, unless `--force` is given, when `.groma/generated.json` was written by a newer groma, and SHALL make no copies when `steps.skills_copy` is `skipped` and no `.groma/generated.json` exists. It SHALL then re-run pending steps and bump `initialized_with`.

#### Scenario: User edited a generated skill
- **WHEN** the user changed `.claude/skills/groma-survey/SKILL.md` and runs `groma update`
- **THEN** that file is kept, reported as "edited, not updated", and replaced only with `--force`

#### Scenario: Older CLI, newer project
- **WHEN** `.groma/generated.json` names a newer `generatedBy` than the CLI and the user runs `groma update`
- **THEN** the command exits with an error, changes nothing and names `--force`

#### Scenario: Declined copy
- **WHEN** `steps.skills_copy` is `skipped`, no `.groma/generated.json` exists and the user runs `groma update`
- **THEN** no skill folder is written
