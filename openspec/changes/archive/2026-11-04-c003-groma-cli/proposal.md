Milestone: m002

## Why

Today the agent installs the methodology and the catalog skills during `/groma`. That depends on the agent's permissions (in every headless run so far, nothing could be installed and everything ended up in `.groma/install.sh`), it is not deterministic, and it spends tokens on work a script does in seconds. OpenSpec shows the better split: a CLI (`openspec init`) puts the skills into the project and sets everything up; the agent then does the work that needs understanding.

## What Changes

- New npm package `groma` with a Node CLI: `npx groma init`, `update`, `status`, `doctor`.
- `groma init` asks (or takes flags for) agents, methodology, workflow layer, catalog skills and review mode, then deterministically:
  - copies the groma skills **as they are** (including their scripts) into each agent's project skill folder, marked with the generating version (hybrid model: the CLI installs and updates, the skills stay self-contained),
  - runs the methodology init and the catalog skill installs,
  - writes `.groma/config.yaml` with those steps marked done,
  - tells the user to run `/groma` in the agent for the survey, docs and agent files.
- `groma update` refreshes generated skill copies to the CLI's version and never overwrites a copy the user edited without `--force`.
- Installation recipes move from Markdown prose into data files read by both the CLI and the skills (`methodologies.yaml`, the existing `catalog.yaml`, a new agent folder table).
- `/groma` reuses what `groma init` did and only runs the remaining steps.
- The Claude plugin and `npx skills add` stay supported; `groma init` detects an existing plugin install and avoids duplicate skills.

## Capabilities

### New Capabilities
- `cli`: the `groma` command, its subcommands, flags, interactive prompts, skill materialization with version markers, update rules, exit codes.

### Modified Capabilities
- `distribution`: npm package as an additional, primary install path; version consistency includes `package.json`; plugin and skills CLI remain.
- `orchestration`: `/groma` skips steps already completed by `groma init` and points to `npx groma init` when installs are pending.
- `methodology-setup`: methodology recipes are a shared data file.
- `skill-catalog`: install recipes per agent are data, executed by the CLI or the skill.

## Impact

- New: `package.json`, `bin/groma.js`, `cli/` (Node ≥ 22, one runtime dependency for YAML), `skills/groma-methodology/methodologies.yaml`, `skills/groma/agents.yaml`, Node tests.
- Changed: `groma-methodology` and `groma-skills` read the data files; `groma` orchestrator reads step state written by the CLI; README install section; version check covers `package.json`.
- Publishing `groma` to npm (owner: Zeotyn) becomes part of the release.
