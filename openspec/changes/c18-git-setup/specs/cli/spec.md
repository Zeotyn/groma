## ADDED Requirements

### Requirement: Repository setup in init
When the target folder is not inside a git work tree, `groma init` SHALL ask whether to set up a git repository, answerable by `--git <init|skip>`, with `init` recommended for greenfield and `skip` for brownfield; `init` SHALL run `git init` with initial branch `main` and write `.gitignore` by the same rules as `/groma`, except that without a stack question the stack rows SHALL come from the manifests at the project root only; `skip` SHALL write `git.enabled: false`. When the target folder is inside a parent work tree, `groma init` SHALL name its top level and ask whether to use it or set up a repository for the project, answerable by `--git <use|init>`, with `use` recommended; `use` SHALL make no commit. At the end of a run in a repository without any commit, `groma init` SHALL offer the first commit by the same rules as `/groma`, answerable by `--commit <yes|no>`. `--yes` SHALL take the recommended option for both.

#### Scenario: Non-interactive greenfield
- **WHEN** the user runs `npx groma-cli init --yes` in an empty folder outside git with a git identity configured
- **THEN** the folder is a repository on `main` with one commit `chore: set up project with groma <version>` and a clean working tree

#### Scenario: Skip
- **WHEN** the user runs `npx groma-cli init --git skip --yes` in the same folder
- **THEN** no `.git/` exists and `.groma/config.yaml` has `git.enabled: false`

#### Scenario: Parent repository
- **WHEN** the user runs `npx groma-cli init --yes` in an empty folder inside a parent work tree
- **THEN** the parent repository is named and used, no repository is set up and nothing is committed

#### Scenario: Stack rows from manifests
- **WHEN** the user runs `npx groma-cli init --git init --yes` in a folder outside git that has a `package.json`
- **THEN** `.gitignore` lists `node_modules/` and the rows for all stacks
