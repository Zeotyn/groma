## ADDED Requirements

### Requirement: Git steps in the loop
In a git repository groma-loop SHALL, following the `git` settings: at start, create and switch to a branch named after the change id when `branch_per_change` is true and the current branch is not already that branch; during apply, commit each review unit after its tests passed and its review stopped clean, in the configured commit style, with the user's git identity; at archive, commit the archive, integrate the branch with the configured strategy, and push the main branch when `push` is `auto`, or after the user agrees when `push` is `ask`. The working-tree base used for reviews and docs impact SHALL be `git merge-base <main> <branch>` when on a change branch.

#### Scenario: Full run with defaults
- **WHEN** groma-loop runs `c007-cache` from `main` with default git settings
- **THEN** it works on branch `c007-cache`, makes one commit per task group, and at the end `main` is fast-forwarded to the rebased branch, the branch still exists, and groma asks before pushing

#### Scenario: Push never
- **WHEN** `push: never`
- **THEN** groma integrates locally and the summary says "not pushed (git.push: never)"

### Requirement: Git escalations
groma-loop SHALL escalate when the working tree has uncommitted changes at start, when integration conflicts, and when a push is rejected. It SHALL NOT retry a rejected push with force.

#### Scenario: Dirty working tree
- **WHEN** groma-loop starts and `git status --porcelain` lists modified files
- **THEN** groma stops before creating a branch and offers: commit or stash them yourself, or continue without git steps
