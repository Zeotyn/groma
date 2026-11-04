## Context

`skills/groma-methodology/scripts/status.sh` loops over active changes and prints at most one reminder each. Then it prints pending ADRs. Without any line it prints "nothing open". It already sources `lib-changes.sh` for the list of changes and uses `git log` and `git status` for single paths. Milestones (`m`) are skipped by the test reminder. Their only possible reminders are "verify, then archive" (all ticked) and stale (no commit for 14 days). A milestone whose children are archived and whose gate tasks are open falls through both. Constraints: POSIX sh (ADR 0005), read-only, no network, fast enough for a session hook and later C007's hook (target under 300 ms on this repository).

## Goals / Non-Goals

**Goals:**
- No false "nothing open".
- Milestone gates, uncommitted work and unpushed commits are visible as one line each.
- Existing output lines keep their format.

**Non-Goals:**
- The next-action ladder, hooks and short output (C007).
- Fetching from remotes or querying CI.
- Honoring `git.push` (C006 introduces it; C006 maps `push: never` to `unpushed: false`).

## Decisions

### D1: A milestone is "at its gate" when no active change references it
The script collects the `Milestone: mNNN` lines from the first lines of each active change's `proposal.md`. An active `m` change with open tasks and no referencing active change gets `gate: <first open task text>`, with the task number kept, the text cut to 60 characters, and backticks removed. This replaces the stale reminder for that milestone, because a waiting gate is the more useful message.

Alternatives: parse milestone task groups by heading ("Child changes" ticked, "Release gate" open) (rejected: depends on headings from groma's template; milestones written by hand differ); read the child table's Status column (rejected: it is prose maintained by hand, and C004 already showed it lags behind).

### D2: Repository lines come after change lines, local state only
- Uncommitted: `git status --porcelain` line count.
- Unpushed: `git rev-list --count @{upstream}..<main>` for the main branch (`git symbolic-ref refs/remotes/origin/HEAD`, else `main`, else `master`). No upstream means no unpushed line.

Both are skipped outside git. No `git fetch`: the count is against the last known remote state, which is what a local reminder can promise.

Alternatives: fetch first (rejected: network, slow, can prompt for credentials in a session hook); count unpushed on the current branch instead of main (rejected: change branches are kept and never pushed under the user's workflow, so they would remind forever).

### D3: Two toggles in `reminders`, default on
`uncommitted` and `unpushed` follow the existing pattern (`untested_tasks`). C006 later sets `unpushed: false` when `git.push: never`.

Alternatives: one `repository` toggle (rejected: users who never push from this clone still want the uncommitted reminder).

## Risks / Trade-offs

- [A milestone without `Milestone:` lines in its children always looks "at its gate"] → that is correct for the reminder: the gate tasks are the open work. The message names the task, so a wrong case is obvious.
- [Stale upstream refs make the unpushed count wrong] → the count is against local refs by design. The message stays correct after the next fetch or push.
- [Runtime grows with the number of changes] → one extra `grep` per active proposal and two git calls in total. Measured in task 2.3.

## Migration Plan

Validator accepts the new keys, and missing keys mean `true`. Existing projects see new lines on the next run. `upgrades.md` gets no row, because nothing needs to be written.
