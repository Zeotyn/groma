# git-workflow Specification

## Purpose
Makes a project's git workflow explicit: how changes get a branch, how commits are written, how branches are integrated into the main branch, and when groma pushes, so every agent integrates the same way.
## Requirements
### Requirement: Git settings
The `git` section of `.groma/config.yaml` SHALL define `integrate` (`rebase`, `merge`, `squash`; default `rebase`), `branch_per_change` (default `true`), `commits` (`conventional`, `free`; default `conventional`) and `push` (`ask`, `auto`, `never`; default `ask`). The main branch SHALL be the remote's default branch, else `main`, else `master`.

#### Scenario: Defaults
- **WHEN** the config has no `git` section
- **THEN** groma behaves as `integrate: rebase`, `branch_per_change: true`, `commits: conventional`, `push: ask`

### Requirement: Integration strategies
`rebase` SHALL rebase the change branch onto the main branch and then fast-forward the main branch, producing no merge commit. `merge` SHALL create a merge commit with `--no-ff`. `squash` SHALL squash the branch into one commit on the main branch whose subject names the change id. groma SHALL never rewrite commits that are already on the main branch.

#### Scenario: Rebase integration
- **WHEN** `integrate: rebase` and `main` gained commits after `c007-cache` branched off
- **THEN** `c007-cache` is rebased onto `main`, `main` is fast-forwarded to it, and `git log --merges main` shows no new commit

#### Scenario: Squash integration
- **WHEN** `integrate: squash` and `c007-cache` has five commits
- **THEN** `main` gains one commit whose subject contains `c007-cache`

### Requirement: Safety rules
groma SHALL NOT force-push, delete branches, or rewrite pushed commits on the main branch. On a rebase or merge conflict it SHALL abort the operation, leaving both branches as before, and escalate. It SHALL NOT commit files that were modified before the loop started.

#### Scenario: Rebase conflict
- **WHEN** rebasing `c007-cache` onto `main` conflicts in `src/cache.ts`
- **THEN** groma runs `git rebase --abort`, `main` and `c007-cache` point to the same commits as before, and the escalation names `src/cache.ts`

### Requirement: History-based recommendation
A read-only script SHALL analyze the last 200 commits of the main branch and print the recommended `integrate` and `commits` values with evidence: counts of merge commits, "Merge pull request" subjects, subjects ending in `(#<n>)`, and subjects in conventional-commit form. It SHALL recommend `merge` when most merges are pull-request merges, `squash` when most subjects end in `(#<n>)` and there are few merges, `rebase` otherwise; `conventional` when at least 70 percent of subjects match the conventional form. Without commits it SHALL print the defaults with "no history".

#### Scenario: Squash-based project
- **WHEN** 34 of 40 recent subjects end in `(#<n>)` and there are no merge commits
- **THEN** the script recommends `integrate: squash` and prints "34 of 40 subjects end in (#n)"

#### Scenario: Empty repository
- **WHEN** the repository has no commits
- **THEN** the script prints `integrate: rebase`, `commits: conventional` and "no history"

