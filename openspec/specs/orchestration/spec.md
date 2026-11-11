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
When `.groma/config.yaml` marks `config`, `methodology` and `skills` as `done` (written by `groma init`), `/groma` SHALL NOT repeat those steps or their questions and SHALL start with detect, then the content interview (purpose, users, vision), docs and agent files. When install steps are `pending`, `/groma` SHALL recommend `npx groma-cli init` (or `npx groma-cli update`) before installing anything itself.

#### Scenario: After groma init
- **WHEN** the user runs `/groma` right after `npx groma-cli init --yes`
- **THEN** groma does not ask for agents, methodology or skills and goes on with detect, interview, docs and agents

#### Scenario: Pending installs
- **WHEN** `steps.skills` is `pending`
- **THEN** the summary's next action is "Run `npx groma-cli update` in a terminal", not an agent-side install

### Requirement: Style tools question
The interview SHALL ask for style tools only when detection found none. The recommended option SHALL be the table's default tools for the stack. In brownfield projects the recommended option SHALL be "document only", so that adding tools to existing code stays an explicit choice.

#### Scenario: Greenfield Python
- **WHEN** the project is greenfield and the user chose Python
- **THEN** the interview asks "Set up Ruff for formatting and linting? (recommended)"

#### Scenario: Brownfield with tools
- **WHEN** detection found `.prettierrc`
- **THEN** the interview asks no style tools question

