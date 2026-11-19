---
status: accepted
date: 2026-11-19
decision-makers: Eugen Waldschmidt
evidence: [skills/groma/scripts/first-commit.sh, skills/groma/SKILL.md, cli/init.js, tests/scripts/first-commit.bats]
origin: c18-git-setup#D2
---

# Offer the first commit before the summary, only in a repository without commits

## Context and Problem Statement

groma-loop requires a clean working tree. After a setup run in a new repository every file is untracked. When and what does groma commit?

## Considered Options

* One commit before the summary, only when the repository has no commit
* Commit only groma's own files
* A commit after every step
* Offer a commit in repositories with history too

## Decision Outcome

Chosen option: "One commit before the summary, only when the repository has no commit", because it records every file the run wrote and starts the history cleanly. `first-commit.sh` stages what `git status --porcelain` lists below the project (honouring `.gitignore`), commits with `git commit -F` and the message `chore: set up project with groma <version>`, the user's identity and no `--no-verify`, and limits the commit to the project folder. Without an identity it commits nothing and prints the commands for the summary's next action. The identity check reads `git config user.name` and `git config user.email` only and errs on the safe side: an identity set only through `GIT_AUTHOR_*` or `GIT_COMMITTER_*` counts as none, so no commit is made under a name the user did not configure.

Consent: `/groma` and an interactive `npx groma-cli init` ask both questions. `npx groma-cli init` without a TTY and without `--yes` takes the recommended answers, as it does for every other question, and prints a `No TTY: using ...` note that names `git` and `commit`; this is the documented non-TTY fallback of `groma init`, so a greenfield folder gets `git init` and the first commit there. `--git skip` or `--commit no` turn them off without a TTY.

Committing only groma's files lost because the user's files would stay untracked. A commit per step lost as noise. Committing into an existing history lost because groma-loop commits there per change with its own rules.

### Consequences

* Good, because a new project is ready for groma-loop right after setup.
* Bad, because a failing hook or signing setup leaves the commit to the user.

### Confirmation

`tests/scripts/first-commit.bats` covers identity, no identity, existing history, `.gitignore` and a parent repository.
