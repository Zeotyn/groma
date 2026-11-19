---
status: proposed
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

Chosen option: "One commit before the summary, only when the repository has no commit", because it records every file the run wrote and starts the history cleanly. `first-commit.sh` stages what `git status --porcelain` lists below the project (honouring `.gitignore`), commits with `git commit -F` and the message `chore: set up project with groma <version>`, the user's identity and no `--no-verify`, and limits the commit to the project folder. Without an identity it commits nothing and prints the commands for the summary's next action.

Committing only groma's files lost because the user's files would stay untracked. A commit per step lost as noise. Committing into an existing history lost because groma-loop commits there per change with its own rules.

### Consequences

* Good, because a new project is ready for groma-loop right after setup.
* Bad, because a failing hook or signing setup leaves the commit to the user.

### Confirmation

`tests/scripts/first-commit.bats` covers identity, no identity, existing history, `.gitignore` and a parent repository.
