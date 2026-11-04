## MODIFIED Requirements

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

### Requirement: Dry run and print
`--dry-run` SHALL print every file and command init would write or run and change nothing. `--print` SHALL write the commands to `.groma/install.sh` instead of running them, and still materialize skills and write the config.

#### Scenario: Dry run
- **WHEN** the user runs `npx groma-cli init --dry-run --yes`
- **THEN** the planned files and commands are printed, and the project is byte-identical afterwards

