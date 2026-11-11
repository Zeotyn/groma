---
status: proposed
date: 2026-11-11
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-agents/references/git-strategies.md, skills/groma-loop/SKILL.md, tests/scripts/git-integrate.bats]
origin: c006-git-workflow#D2
---

# Integrate with three fixed command sequences

## Context and Problem Statement

`git.integrate` has to be carried out the same way by groma-loop and by any agent reading AGENTS.md, and it has to be testable. How are the strategies defined?

## Considered Options

* Three strategies with fixed command sequences in one table (`skills/groma-agents/references/git-strategies.md`): `rebase` is `git rebase <main> <branch>`, `git switch <main>`, `git merge --ff-only <branch>`; `merge` is `git switch <main>`, `git merge --no-ff <branch>`; `squash` is `git switch <main>`, `git merge --squash <branch>`, `git commit` with the subject `<type>(<change-id>): <proposal title>`. The main branch is the remote's default branch (`git symbolic-ref refs/remotes/origin/HEAD`), else `main`, else `master`
* Free-form strategy text in the config
* `rebase` without the fast-forward, leaving the integration to the user

## Decision Outcome

Chosen option: "three fixed sequences in one table", because fixed commands are testable in a temporary repository and every agent reads them the same way, while free text is interpreted differently by every agent. Leaving the fast-forward to the user was rejected because the user asked groma-loop to finish the change. The table is read by groma-agents when it renders AGENTS.md and by groma-loop when it integrates, so the tested text is the text agents follow.

### Consequences

* Good, because `tests/scripts/git-integrate.bats` runs the table's rows and fails when a sequence stops producing the promised history.
* Good, because `rebase` yields a linear history without a merge commit, which is what the originating problem asked for.
* Bad, because a project with a fourth practice (for example merge queues) has to pick the closest of the three.

### Confirmation

`tests/scripts/git-integrate.bats`: rebase leaves no merge commit and fast-forwards main, merge creates exactly one merge commit, squash creates one commit whose subject names the change.

## More Information

From design decision D2 of c006-git-workflow. Related: ADR 0004 (knowledge in reference tables), ADR 0039.
