Milestone: m002

## Why

`freshness.sh` reports 15 of 17 docs in this repository as stale. Eight of them are ADRs, which record a decision at a point in time and never go stale because code changed. Two more point at a change folder that moved when it was archived. The noise hides the real findings (`architecture.md` and `concept.md` do not know `groma-loop`), and C004 will build its docs gate on this script, so the detector has to be right first.

## What Changes

- ADRs (files under `<docs>/adr/`) are no longer checked against code changes. Instead, an ADR with `status: proposed` older than 30 days (`--adr-days`) is reported as stale with the reason "proposed since <date>, accept or reject".
- Source paths inside the docs folder are ignored: docs describe code, not each other. A doc whose `sources` are all inside the docs folder gets only the review-date check.
- New result kind `broken` for a doc whose `sources` name a path that does not exist, or a path inside a change folder (`openspec/changes/`), which moves on archive. The summary line gains `broken=<n>` at the end.
- groma-lay-out and the doc templates state that `sources` name code and config paths, never change folders. groma-survey turns `broken` lines into findings.
- groma's own `docs/concept.md` and `docs/risks.md` get `sources` without change-folder paths.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `brownfield-discovery`: stale-doc detection exempts ADRs from code-change staleness, flags long-proposed ADRs, ignores doc-to-doc sources and reports broken sources.
- `docs-scaffold`: freshness frontmatter rule says what `sources` may contain.

## Impact

- `skills/groma-survey/scripts/freshness.sh`, `skills/groma-survey/SKILL.md`, `skills/groma-survey/templates/findings.md`
- `skills/groma-lay-out/SKILL.md`, `skills/groma-lay-out/references/doc-slots.md`
- `tests/scripts/freshness.bats`
- `docs/concept.md`, `docs/risks.md` (frontmatter only)
- Output format: the summary line gains a trailing `broken=<n>` field; the three existing fields keep their position.
