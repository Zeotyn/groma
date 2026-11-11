---
status: proposed
date: 2026-11-11
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-loop/SKILL.md, skills/groma-agents/references/git-strategies.md, tests/scripts/git-integrate.bats, tests/evals/assert.sh]
origin: c006-git-workflow#D3
---

# Abort and escalate on git conflicts, never force

## Context and Problem Statement

groma-loop now rebases, merges and pushes inside the user's repository. A conflicting rebase, a dirty working tree at start or a rejected push are the moments where an autonomous agent can damage work. What does the loop do at these points?

## Considered Options

* Abort and escalate: a conflicting rebase or merge is aborted (`git rebase --abort`, `git merge --abort`, `git reset --merge` for a squash), so both branches point to the commits they had before, and escalated with the conflicting paths; a rejected push escalates; a dirty tree at start escalates before branching, with the option to continue without git steps; groma never deletes branches and never force-pushes, and the rebase rewrites only the change branch, which is not on the main branch yet
* Let the agent resolve conflicts
* Stash a dirty tree automatically

## Decision Outcome

Chosen option: "abort and escalate", because a silent semantic merge is the riskiest step in the whole flow and a person decides it faster than a reviewer round can catch it. An automatic stash hides the user's work in a place they may not look. Aborting is cheap: both refs are unchanged, so the user can resolve the conflict and run the integration commands themselves.

### Consequences

* Good, because every git step of the loop is reversible up to the push, and the push is never forced.
* Good, because the escalation names the paths, so the user starts with the facts.
* Bad, because a project with frequent conflicts gets frequent stops; shorter changes are the remedy, not automatic resolution.

### Confirmation

`tests/scripts/git-integrate.bats` (every conflict aborts with both refs unchanged and a clean tree); `tests/evals/assert.sh` (conflict-loop-openspec: main unchanged, escalation names the file, no `--force` in the log).

## More Information

From design decision D3 of c006-git-workflow. Related: ADR 0006 (safe to run and re-run), ADR 0038.
