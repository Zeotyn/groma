# orchestration Specification

## Purpose
Provides the single `/groma` entry point that guides a user step by step from an empty or existing folder to a documented, configured project, and safely re-runs as an update.
## Requirements
### Requirement: Guided step sequence
The orchestrator SHALL run these steps in order: detect project type, interview, write config, set up methodology, install selected skills, create or complete docs, write agent instructions, print a summary. Before each step it SHALL state the step number, the total and what the step will do.

#### Scenario: Fresh run in an empty folder
- **WHEN** the user invokes `/groma` in an empty folder
- **THEN** the orchestrator announces "Step 1 of 8: detect project type" and proceeds through all eight steps in order

#### Scenario: User stops midway
- **WHEN** the user aborts after step 4
- **THEN** all files written so far remain valid, and the next `/groma` run resumes at step 5 based on `.groma/config.yaml` state

### Requirement: Interview with recommendations
The interview SHALL ask only questions whose answers are not derivable from the folder. Every question SHALL offer a recommended default.

#### Scenario: Greenfield interview
- **WHEN** the project is greenfield
- **THEN** the interview asks what is being built, for whom, whether it has a UI, which methodology and which agents, each with a recommended option

#### Scenario: Brownfield interview skips known facts
- **WHEN** the project is brownfield and contains `.github/` and a frontend framework
- **THEN** the interview does not ask whether the project has a UI or uses GitHub

### Requirement: Idempotent update mode
When `.groma/config.yaml` exists, the orchestrator SHALL run in update mode: add newly mandatory docs, re-run freshness checks, offer updates for installed skills, and leave existing content untouched.

#### Scenario: Re-run after suite upgrade
- **WHEN** `initialized_with` is `groma@0.1.0` and the installed suite is `0.2.0`, which added a mandatory doc
- **THEN** the orchestrator creates only the missing doc and reports which version introduced it

#### Scenario: Re-run with no changes
- **WHEN** `/groma` runs twice in a row without changes in between
- **THEN** the second run writes no files except an updated findings report and says that nothing changed

### Requirement: Graceful degradation
The orchestrator SHALL detect which groma sub-skills are installed and SHALL skip missing ones with a message naming the skill and its install command.

#### Scenario: Only docs scaffold installed
- **WHEN** only `groma` and `groma-lay-out` are installed
- **THEN** the orchestrator skips the methodology and skill-install steps and prints `npx skills add <owner>/groma --skill groma-methodology` for each missing skill

### Requirement: Final summary
The orchestrator SHALL end with a summary listing files created, findings by severity, and one concrete next action.

#### Scenario: Summary after brownfield run
- **WHEN** a brownfield run completes with 3 stale docs and 0 ADRs found
- **THEN** the summary lists the created files, reports "0 ADRs found, 4 proposed", "3 stale docs", and names the next action, e.g. "Review docs/adr/0003-*.md"

### Requirement: Reuse of CLI setup
When `.groma/config.yaml` marks `config`, `methodology` and `skills` as `done` (written by `groma init`), `/groma` SHALL NOT repeat those steps or their questions and SHALL start with detect, then the content interview (purpose, users, vision), docs and agent files. When install steps are `pending`, `/groma` SHALL offer to run the pending third-party installs itself with consent, or recommend `npx groma-cli update`; copying and updating the groma skills SHALL NOT require the CLI.

#### Scenario: After groma init
- **WHEN** the user runs `/groma` right after `npx groma-cli init --yes`
- **THEN** groma does not ask for agents, methodology or skills and goes on with detect, interview, docs and agents

#### Scenario: Pending installs
- **WHEN** `steps.skills` is `pending`
- **THEN** groma offers to run the pending installs with consent, and names `npx groma-cli update` as the terminal alternative

### Requirement: Style tools question
The interview SHALL ask for style tools only when detection found none. The recommended option SHALL be the table's default tools for the stack. In brownfield projects the recommended option SHALL be "document only", so that adding tools to existing code stays an explicit choice.

#### Scenario: Greenfield Python
- **WHEN** the project is greenfield and the user chose Python
- **THEN** the interview asks "Set up Ruff for formatting and linting? (recommended)"

#### Scenario: Brownfield with tools
- **WHEN** detection found `.prettierrc`
- **THEN** the interview asks no style tools question

### Requirement: Integration strategy question
In a git repository the interview SHALL ask for the integration strategy and push policy. In greenfield projects the recommended option SHALL be `rebase` with `push: ask`. In brownfield projects the recommended option SHALL be the history-based recommendation, shown with its evidence.

#### Scenario: Brownfield with pull-request merges
- **WHEN** the history script reports 28 "Merge pull request" commits out of 30 merges
- **THEN** the interview recommends `merge` and shows "28 of 30 merges are pull-request merges"

### Requirement: Agent-side skill materialization
When the CLI has not copied the groma skills, `/groma` SHALL offer once, recommended yes, to put them into the project skill folder of each selected agent, and on yes SHALL run `materialize.sh`, which applies the same rules as `groma init`: copied SKILL.md files carry `metadata.generatedBy: groma@<version>`, every generated file is recorded with its SHA-256 in `.groma/generated.json`, and a folder groma did not create is never touched. In update mode `/groma` SHALL refresh the copies with `materialize.sh --update`: unchanged copies are replaced, edited copies are kept and reported, and a file is deleted only when it is unchanged and groma no longer ships it (the file left a copied skill, or its skill is listed as retired). Copies of skills that the running groma merely does not contain SHALL be kept. `materialize.sh` SHALL refuse a source that is itself a copy groma made (its `SKILL.md` carries `generatedBy`), SHALL refuse without `--allow-downgrade` to replace copies of a newer groma, SHALL never copy a folder onto itself and SHALL never write through a symbolic link. A run that is interrupted SHALL leave every file it wrote recorded in `.groma/generated.json`.

#### Scenario: Plugin-only setup
- **WHEN** a user with only the groma plugin runs `/groma` in a fresh repository with agents claude and copilot and accepts the default
- **THEN** `.claude/skills/groma/SKILL.md` and `.github/skills/groma/SKILL.md` exist with `generatedBy`, `.groma/generated.json` lists every copied file, and a teammate who clones the repository has the groma skills

#### Scenario: Same result as the CLI
- **WHEN** the same fixture is set up once by `/groma` with the plugin only and once by `npx groma-cli init`
- **THEN** both projects hold the same copied files and the same `.groma/generated.json`

#### Scenario: Edited copy on update
- **WHEN** the user edited `.claude/skills/groma-survey/SKILL.md` and `/groma` runs in update mode
- **THEN** that file is kept and reported as edited, and the other copies move to the new version

#### Scenario: Smaller or older source
- **WHEN** `/groma` runs in update mode from a bundle with three skills, or from an older groma, in a project that holds copies of all skills
- **THEN** no copy of a skill outside that source is deleted, and an older groma changes nothing without `--allow-downgrade`, also when `--force` is given

#### Scenario: Run from copies groma made
- **WHEN** a teammate without the plugin runs `/groma` from `.claude/skills/groma/` of the project, whose `SKILL.md` carries `generatedBy`
- **THEN** `materialize.sh` writes nothing, and groma tells the user how to update the copies

#### Scenario: Project-level install as source
- **WHEN** the groma skills were installed with `npx skills add` into `.agents/skills/` of the project and `/groma` copies for claude, codex and copilot
- **THEN** `.github/skills/` gets the copies, `.agents/skills/` is left as it is, and links in `.claude/skills/` are reported as conflicts

#### Scenario: Declined
- **WHEN** the user answers no
- **THEN** no skill folder is written and `steps.skills_copy` is `skipped`

