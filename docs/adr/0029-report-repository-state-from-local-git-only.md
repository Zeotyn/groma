---
status: proposed
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/scripts/status.sh, tests/scripts/status.bats]
origin: f002-status-milestone-gates#D2
---

# Report uncommitted and unpushed work from local git state only

## Context and Problem Statement

`status.sh` said "nothing open" while files were uncommitted and commits on the main branch were not pushed. It runs in a session hook, so it must stay fast, read-only and offline.

## Decision Drivers

* No network, no credential prompts in a session hook
* No reminder that never goes away under a workflow that keeps change branches local

## Considered Options

* Local state only: `git status --porcelain` and `git rev-list --count <main>@{upstream}..<main>`, no fetch
* Fetch from the remote first
* Count unpushed commits on the current branch instead of main

## Decision Outcome

Chosen option: "Local state only", because a local reminder can only promise the last known remote state. The main branch comes from `refs/remotes/origin/HEAD`, else `main`, else `master`. No upstream means no unpushed line. Both lines come after the change lines and are skipped outside git.

### Consequences

* Good, because the script stays read-only, offline and fast.
* Bad, because a stale remote ref makes the unpushed count wrong until the next fetch or push.

### Confirmation

`tests/scripts/status.bats` covers the uncommitted count, the unpushed count against a local bare upstream, main instead of the current branch, no upstream and outside git.

## Pros and Cons of the Options

### Fetch first

* Good, because the count matches the remote.
* Bad, because it needs the network, is slow and can prompt for credentials in a session hook.

### Count on the current branch

* Good, because it covers work on feature branches.
* Bad, because change branches are kept and never pushed under the user's workflow, so they would remind forever.

## More Information

From design decision D2 of f002-status-milestone-gates. Related: ADR 0027, ADR 0030.
