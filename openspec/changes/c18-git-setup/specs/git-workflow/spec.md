## MODIFIED Requirements

### Requirement: Git settings
The `git` section of `.groma/config.yaml` SHALL define `enabled` (default `true`), `integrate` (`rebase`, `merge`, `squash`; default `rebase`), `branch_per_change` (default `true`), `commits` (`conventional`, `free`; default `conventional`) and `push` (`ask`, `auto`, `never`; default `ask`). `enabled: false` SHALL mean the project does not use git: groma SHALL run no git command in it and SHALL ignore the other `git` keys. The main branch SHALL be the remote's default branch, else `main`, else `master`.

#### Scenario: Defaults
- **WHEN** the config has no `git` section
- **THEN** groma behaves as `enabled: true`, `integrate: rebase`, `branch_per_change: true`, `commits: conventional`, `push: ask`

#### Scenario: Git off
- **WHEN** the config has `git.enabled: false`
- **THEN** groma-loop runs no git step and says once in its summary that git is off for the project

## ADDED Requirements

### Requirement: Ignore file for a new repository
When groma set up the repository and the project has no `.gitignore`, groma SHALL write `.gitignore` from the stack's rows of a reference table plus the rows for all stacks. An existing `.gitignore` SHALL NOT be changed.

#### Scenario: Node project
- **WHEN** groma set up the repository in a project whose stack is Node and that has no `.gitignore`
- **THEN** `.gitignore` lists `node_modules/` and the rows for all stacks, and is committed with the first commit when the user agreed to it

#### Scenario: Existing ignore file
- **WHEN** the project has a `.gitignore`
- **THEN** it is byte-identical after the run
