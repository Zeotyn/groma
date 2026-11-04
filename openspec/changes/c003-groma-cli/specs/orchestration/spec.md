## ADDED Requirements

### Requirement: Reuse of CLI setup
When `.groma/config.yaml` marks `config`, `methodology` and `skills` as `done` (written by `groma init`), `/groma` SHALL NOT repeat those steps or their questions and SHALL start with detect, then the content interview (purpose, users, vision), docs and agent files. When install steps are `pending`, `/groma` SHALL recommend `npx groma init` (or `npx groma update`) before installing anything itself.

#### Scenario: After groma init
- **WHEN** the user runs `/groma` right after `npx groma init --yes`
- **THEN** groma does not ask for agents, methodology or skills and goes on with detect, interview, docs and agents

#### Scenario: Pending installs
- **WHEN** `steps.skills` is `pending`
- **THEN** the summary's next action is "Run `npx groma update` in a terminal", not an agent-side install
