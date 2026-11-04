## ADDED Requirements

### Requirement: Git workflow section
The generated AGENTS.md SHALL contain a "Git workflow" section derived from the `git` settings: branch naming, commit style, the integration commands for the configured strategy, that a request to "merge" a branch means this strategy, to stop and ask on conflicts, and that force-push and deleting branches are not allowed.

#### Scenario: Rebase project
- **WHEN** `integrate: rebase`
- **THEN** AGENTS.md says to integrate with `git rebase <main> <branch>` followed by `git merge --ff-only <branch>` and that "merge" requests mean exactly this
