## ADDED Requirements

### Requirement: Agent-side skill materialization
When the CLI has not copied the groma skills, `/groma` SHALL offer once, recommended yes, to put them into the project skill folder of each selected agent, and on yes SHALL run `materialize.sh`, which applies the same rules as `groma init`: copied SKILL.md files carry `metadata.generatedBy: groma@<version>`, every generated file is recorded with its SHA-256 in `.groma/generated.json`, and a folder groma did not create is never touched. In update mode `/groma` SHALL refresh the copies with `materialize.sh --update`: unchanged copies are replaced, edited copies are kept and reported, files of removed skills are deleted only when unchanged.

#### Scenario: Plugin-only setup
- **WHEN** a user with only the groma plugin runs `/groma` in a fresh repository with agents claude and copilot and accepts the default
- **THEN** `.claude/skills/groma/SKILL.md` and `.github/skills/groma/SKILL.md` exist with `generatedBy`, `.groma/generated.json` lists every copied file, and a teammate who clones the repository has the groma skills

#### Scenario: Same result as the CLI
- **WHEN** the same fixture is set up once by `/groma` with the plugin only and once by `npx groma-cli init`
- **THEN** both projects hold the same copied files and the same `.groma/generated.json`

#### Scenario: Edited copy on update
- **WHEN** the user edited `.claude/skills/groma-survey/SKILL.md` and `/groma` runs in update mode
- **THEN** that file is kept and reported as edited, and the other copies move to the new version

#### Scenario: Declined
- **WHEN** the user answers no
- **THEN** no skill folder is written and `steps.skills_copy` is `skipped`

## MODIFIED Requirements

### Requirement: Reuse of CLI setup
When `.groma/config.yaml` marks `config`, `methodology` and `skills` as `done` (written by `groma init`), `/groma` SHALL NOT repeat those steps or their questions and SHALL start with detect, then the content interview (purpose, users, vision), docs and agent files. When install steps are `pending`, `/groma` SHALL offer to run the pending third-party installs itself with consent, or recommend `npx groma-cli update`; copying and updating the groma skills SHALL NOT require the CLI.

#### Scenario: After groma init
- **WHEN** the user runs `/groma` right after `npx groma-cli init --yes`
- **THEN** groma does not ask for agents, methodology or skills and goes on with detect, interview, docs and agents

#### Scenario: Pending installs
- **WHEN** `steps.skills` is `pending`
- **THEN** groma offers to run the pending installs with consent, and names `npx groma-cli update` as the terminal alternative
