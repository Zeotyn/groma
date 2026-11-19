## ADDED Requirements

### Requirement: Repository setup in init
When the target folder is not inside a git work tree, `groma init` SHALL ask whether to set up a git repository, answerable by `--git <init|skip>`, with `init` recommended for greenfield and `skip` for brownfield; `init` SHALL run `git init` with initial branch `main` and write `.gitignore` by the same rules as `/groma`, `skip` SHALL write `git.enabled: false`. At the end of a run in a repository without any commit, `groma init` SHALL offer the first commit by the same rules as `/groma`, answerable by `--commit <yes|no>`. `--yes` SHALL take the recommended option for both.

#### Scenario: Non-interactive greenfield
- **WHEN** the user runs `npx groma-cli init --yes` in an empty folder outside git with a git identity configured
- **THEN** the folder is a repository on `main` with one commit `chore: set up project with groma <version>` and a clean working tree

#### Scenario: Skip
- **WHEN** the user runs `npx groma-cli init --git skip --yes` in the same folder
- **THEN** no `.git/` exists and `.groma/config.yaml` has `git.enabled: false`
