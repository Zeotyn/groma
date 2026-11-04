## Context

`freshness.sh` rule (b) compares the newest commit under a doc's `sources` with the doc's last commit, to the second. `last_reviewed` is used only by rule (a), review overdue. Since C004, docs are updated inside the change that touches the code, and the docs gate checks this per change with `docs-impact.sh`. A change usually commits its docs before its last review-round fixes, so after archive rule (b) reports docs that were reviewed that same day. F001 deliberately left `last_reviewed` handling unchanged; this fix revisits that now that the docs gate exists.

## Goals / Non-Goals

**Goals:**
- Docs reviewed on the day of the last source change are fresh.
- Docs without `last_reviewed` behave as before.

**Non-Goals:**
- Second-level review timestamps.
- Linking source commits to changes.

## Decisions

### D1: `last_reviewed` covers source commits up to the end of that day
Rule (b) becomes: stale when `newest_source_commit > doc_commit` and `day(newest_source_commit) > last_reviewed`. The day uses the same UTC day arithmetic as rule (a) (`ymd`).

Alternatives:
- Ignore source commits that belong to the same change as the doc commit. Rejected: the script would need to know about changes, and that does not work without a methodology.
- Require `last_reviewed` to be strictly after the commit day. Rejected: the C004 case happens on one day and would stay stale.
- Compare against the commit that last changed `last_reviewed` (`git log -L`). Rejected: slow, and the archive sync often does not change the value, as in C004.

## Risks / Trade-offs

- [Code changed later on the review day without a doc update stays unflagged] → inside a change, `docs-impact.sh` catches it. Outside a change, the next day's commit flags it. The window is at most one day of commits.
- [Someone bumps `last_reviewed` without reading the doc] → same trust as rule (a) already has. The date is a claim made by a human or by the archive sync.

## Migration Plan

None. Fewer stale lines on the next run.
