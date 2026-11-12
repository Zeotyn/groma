---
status: proposed
date: 2026-11-12
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/scripts/next.sh, tests/scripts/next.bats]
origin: c007-next-action#D3
---

# Cache the next action on repository state

## Context and Problem Statement

A status line calls `next.sh --short` on every refresh, which can be several times a second. A cold run of the ladder takes 0.66 to 0.79 s on this repository, because it runs `status.sh`. The suggestion only changes when the repository changes: a commit, an edit, a push, a config change or a change folder update.

## Decision Drivers

* The status line must stay under 300 ms
* A suggestion must never be stale after a commit or a push
* groma writes only into `.groma/` in a target project (ADR 0006)

## Considered Options

* Cache keyed on repository state: `HEAD`, `git status --porcelain`, local and remote branch heads, the content of `.groma/config.yaml`, plus a `find -newer` check on the changes folder
* Time-based cache
* No cache

## Decision Outcome

Chosen option: "Cache keyed on repository state", because every event that can change the suggestion also changes the key, and a warm hit takes 0.06 to 0.21 s.

### Consequences

* Good, because a commit, an edit or a push invalidates the cache at once.
* Good, because the cache lives in a self-ignoring `.groma/.cache/` folder, so it never shows up as uncommitted work, and is only used when `.groma/` exists.
* Bad, because a key still costs a few git calls per refresh.
* Neutral, because rung 1 (a rebase or merge in progress) is checked before the cache lookup and never cached.

### Confirmation

`tests/scripts/next.bats` covers a cache hit that skips `status.sh`, and a miss after a commit, after a working-tree change and after a push.

## Pros and Cons of the Options

### Time-based cache

* Bad, because it is stale right after a commit, which is exactly when the suggestion changes.

### No cache

* Bad, because the status line calls the script on every refresh and a cold run is too slow for that.

## More Information

From design decision D3 of c007-next-action. Related: ADR 0006, ADR 0043.
