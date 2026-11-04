---
status: proposed
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-survey/scripts/freshness.sh, tests/scripts/freshness.bats]
origin: f003-freshness-reviewed#D1
---

# Let last_reviewed cover source commits up to the end of that day

## Context and Problem Statement

`freshness.sh` flagged a doc as stale when any source commit was newer than the doc's last commit, to the second. A change usually commits its docs before its last review-round fixes, so after archive the docs it reviewed that same day showed up as stale. How should the code-change rule use the review date?

## Considered Options

* A source commit counts only when its UTC day is after `last_reviewed`
* Ignore source commits that belong to the same change as the doc commit
* Require `last_reviewed` to be strictly after the commit day
* Compare against the commit that last changed `last_reviewed` (`git log -L`)

## Decision Outcome

Chosen option: "A source commit counts only when its UTC day is after `last_reviewed`", because it removes the false reports with the date the docs already carry. Matching commits to changes needs a methodology the script cannot assume. A strictly later date keeps the same-day case stale. `git log -L` is slow, and the archive sync often leaves the value unchanged. A doc without `last_reviewed` is still compared by commits only.

### Consequences

* Good, because docs reviewed inside a change stay fresh after its last fixes.
* Bad, because code changed later on the review day without a doc update is not flagged until the next day's commit; inside a change `docs-impact.sh` catches it.

### Confirmation

`tests/scripts/freshness.bats` covers a same-day source commit (fresh), a next-day commit (stale, reason names `last_reviewed`) and a doc without `last_reviewed` (stale as before).

## More Information

From design decision D1 of f003-freshness-reviewed. Related: ADR 0022, ADR 0024.
