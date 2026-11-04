## MODIFIED Requirements

### Requirement: Stale-doc detection
Discovery SHALL flag a doc as stale when its `last_reviewed` exceeds `review_after_days`, or when code under its `sources` (or, without frontmatter, the code it describes) changed after the doc's last commit. Source paths inside the docs folder SHALL be ignored for the code check. ADRs (files under the docs folder's `adr/`) SHALL NOT be checked against code changes; an ADR with `status: proposed` whose `date` (else its last commit) is older than 30 days SHALL be flagged as stale with the reason that it awaits a decision. A doc whose `sources` name a path that does not exist, or a path inside a change folder (`openspec/changes/`), SHALL be reported as broken with each offending path.

#### Scenario: Two-year-old architecture doc
- **WHEN** `docs/architecture.md` was last committed 2 years ago and `src/` has commits from last week
- **THEN** the findings report lists it as stale with both dates

#### Scenario: Accepted ADR after code changes
- **WHEN** `docs/adr/0003-use-postgres.md` has `status: accepted` and `src/` changed after its last commit
- **THEN** the ADR is reported fresh

#### Scenario: Long-proposed ADR
- **WHEN** `docs/adr/0009-cache-layer.md` has `status: proposed` and `date: 2026-09-01`, and today is 2026-11-04
- **THEN** it is reported stale with "proposed since 2026-09-01, accept or reject"

#### Scenario: Index doc with docs sources
- **WHEN** `docs/README.md` has `sources: [docs/]` and `docs/vision.md` changed after it
- **THEN** `docs/README.md` is not reported stale for that change

#### Scenario: Source moved by archiving
- **WHEN** `docs/concept.md` has `sources: [skills/, openspec/changes/c001-x/design.md]` and that change was archived
- **THEN** the doc is reported broken with "source missing: openspec/changes/c001-x/design.md", and the summary counts it under `broken`
