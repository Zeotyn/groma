## ADDED Requirements

### Requirement: Repository offer
When the project folder is not inside a git work tree, the interview SHALL ask once whether to set up a git repository in the project folder, before the integration strategy question. The recommended option SHALL be yes for greenfield and no for brownfield. On yes, groma SHALL run `git init` with `main` as the initial branch and then ask the integration strategy question as in a repository. On no, groma SHALL record `git.enabled: false` and ask no other git question. When the folder is inside a work tree whose top level is a parent folder, the interview SHALL name that top level and ask whether to use it (recommended) or set up a repository for the project.

#### Scenario: Greenfield without git
- **WHEN** the user runs `/groma` in an empty folder that is not inside a git work tree
- **THEN** the interview asks "Set up a git repository here? (recommended)" and, on yes, the folder has a `.git/` with initial branch `main` before the integration strategy question

#### Scenario: Declined
- **WHEN** the user answers no
- **THEN** `.groma/config.yaml` has `git.enabled: false`, no `.git/` exists, and no integration or push question is asked

#### Scenario: Parent repository
- **WHEN** the project folder `~/work/app` is inside a work tree whose top level is `~`
- **THEN** the interview names `~` as the repository and asks whether to use it or set up a repository in `~/work/app`

### Requirement: First commit
Before the summary, when the project is a git repository without any commit, the orchestrator SHALL ask once whether to record the setup as the first commit, with yes recommended. On yes it SHALL stage the files `git status --porcelain` lists and commit them with the user's configured git identity and the message `chore: set up project with groma <version>`, never setting an identity and never using `--no-verify`. Without a git identity it SHALL commit nothing, and the summary's next action SHALL name the commands to set one and commit. A repository that already has a commit SHALL get no question and no commit.

#### Scenario: Yes with identity
- **WHEN** groma set up the repository, `git config user.name` and `user.email` print values and the user answers yes
- **THEN** `git log` shows one commit `chore: set up project with groma <version>` containing every file of the project, and `git status --porcelain` prints nothing

#### Scenario: No identity
- **WHEN** the user answers yes and `git config user.name` prints nothing
- **THEN** no commit is made and the summary's next action is to set `user.name` and `user.email` and commit

#### Scenario: Existing history
- **WHEN** the project's repository already has commits
- **THEN** groma asks no commit question and makes no commit
