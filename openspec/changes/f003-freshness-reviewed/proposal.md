Milestone: m002

## Why

After C004 was archived, `freshness.sh` reported `architecture.md`, `concept.md`, `data-model.md` and `glossary.md` as stale. The docs had been updated inside C004, and `last_reviewed` reads 2026-11-04. Two fix commits from the review rounds touched `skills/` after the docs commit, and the code-change rule compares commit times only. So it ignores that someone reviewed the doc on that day. Every change that updates docs early and fixes code later ends with false stale reports. Since C004, docs are reviewed inside the change, so the review date is the better signal.

## What Changes

- Code-change rule: a doc is stale only when the newest source commit is newer than the doc's last commit **and** its day is after `last_reviewed`. A doc without `last_reviewed` keeps today's behavior.
- The stale reason names both dates as before and adds `last_reviewed` when it is set.
- No change to the review-overdue rule, ADR handling, `broken`, or the output format.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `brownfield-discovery`: stale-doc detection counts `last_reviewed` as a review of the sources up to that day.

## Impact

- `skills/groma-survey/scripts/freshness.sh`, `tests/scripts/freshness.bats`
- Groma's own docs: the four false stale lines disappear.

## Docs impact

- `docs/concept.md`: freshness paragraph names the review-date rule.
- ADR: one proposed ADR for D1 (`origin: f003-freshness-reviewed#D1`).
