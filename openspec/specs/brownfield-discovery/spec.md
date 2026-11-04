# brownfield-discovery Specification

## Purpose
Surveys an existing project without changing it: maps the code, harvests ADRs and docs, detects stale documentation, derives the data model from code artifacts, and reports findings, so the user has a clear picture before working.
## Requirements
### Requirement: Read-only guarantee
Discovery SHALL NOT modify, move or delete any file that existed before the run. It SHALL write only to new paths, `.groma/` and `docs/_groma/`.

#### Scenario: Checksums unchanged
- **WHEN** discovery runs on a project
- **THEN** the SHA-256 of every pre-existing file is identical before and after the run

### Requirement: Code map
Discovery SHALL build a structural map of the code base using the configured discovery skill (graphify by default). It SHALL use the map to describe modules and dependencies in `docs/architecture.md` when that file is created.

#### Scenario: Discovery skill unavailable
- **WHEN** no discovery skill is installed or it fails
- **THEN** discovery falls back to reading the file tree and manifests, and the findings report records "code map: degraded"

### Requirement: ADR harvest
Discovery SHALL search the whole repository for existing ADRs using known locations and patterns, and SHALL list them in `docs/adr/README.md` (if newly created) or in the findings report, without moving them.

#### Scenario: ADRs in legacy folder
- **WHEN** ADRs exist in `doc/architecture/decisions/`
- **THEN** they are listed with their paths, and new ADRs continue their numbering

### Requirement: Retroactive ADR proposals
When a project has no ADRs, discovery SHALL derive decisions visible in the code (e.g. language, framework, database, API style) and SHALL write them as ADRs with status `proposed` and the evidence (file paths) used.

#### Scenario: Project without ADRs
- **WHEN** a Node project with Prisma and PostgreSQL has no ADRs
- **THEN** proposed ADRs exist for at least runtime/framework and database choice, each citing the files that show the decision

### Requirement: Stale-doc detection
Discovery SHALL flag a doc as stale when its `last_reviewed` exceeds `review_after_days`, or when code under its `sources` (or, without frontmatter, the code it describes) changed after the doc's last commit on a day after the doc's `last_reviewed`; a doc without `last_reviewed` SHALL be compared by commits only. Source paths inside the docs folder SHALL be ignored for the code check. ADRs (files under the docs folder's `adr/`) SHALL NOT be checked against code changes; an ADR with `status: proposed` whose `date` (else its last commit) is older than 30 days SHALL be flagged as stale with the reason that it awaits a decision. A doc whose `sources` name a path that does not exist, or a path inside a change folder (`openspec/changes/`), SHALL be reported as broken with each offending path.

#### Scenario: Two-year-old architecture doc
- **WHEN** `docs/architecture.md` was last committed 2 years ago and `src/` has commits from last week
- **THEN** the findings report lists it as stale with both dates

#### Scenario: Reviewed on the day of the code change
- **WHEN** `docs/architecture.md` has `last_reviewed: 2026-11-04`, its last commit is at 10:00 that day, and `skills/` has a commit at 15:00 the same day
- **THEN** the doc is reported fresh

#### Scenario: Code changed after the review day
- **WHEN** `docs/architecture.md` has `last_reviewed: 2026-11-04` and `skills/` has a commit on 2026-11-05 newer than the doc's last commit
- **THEN** the doc is reported stale with the commit date, the doc's commit date and `last_reviewed 2026-11-04`

#### Scenario: No review date
- **WHEN** a doc without frontmatter `last_reviewed` was committed before a source commit on the same day
- **THEN** it is reported stale, as before

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

### Requirement: Stack-agnostic data-model extraction
Discovery SHALL derive the data model from code artifacts in this priority: migrations, schema files, ORM entities, API contracts, code-map inference. Every statement SHALL be tagged `EXTRACTED` or `INFERRED` with its source path. Discovery SHALL NOT connect to databases.

#### Scenario: Migrations and entities disagree
- **WHEN** a migration defines column `email` and the ORM entity lacks it
- **THEN** the data model uses the migration (`EXTRACTED`), and `docs/risks.md` or the findings report records the drift

#### Scenario: User-provided schema dump
- **WHEN** the user ran the provided dump script and `.groma/schema/schema.sql` exists
- **THEN** discovery uses it as the highest-priority source and records it as `EXTRACTED (dump, <date>)`

### Requirement: Findings report
Discovery SHALL write `docs/_groma/findings-<YYYY-MM-DD>.md` with sections for missing docs, stale docs, ADR status, data-model drift, agent-file gaps and suggested snippets for existing files, each with a severity.

#### Scenario: Report content
- **WHEN** discovery finishes
- **THEN** the report exists, and every finding has severity (`high`, `medium`, `low`), evidence and a suggested action

