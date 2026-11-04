## Purpose

Surveys an existing project without changing it: maps the code, harvests ADRs and docs, detects stale documentation, derives the data model from code artifacts, and reports findings, so the user has a clear picture before working.

## ADDED Requirements

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
Discovery SHALL flag a doc as stale when its `last_reviewed` exceeds `review_after_days`, or when code under its `sources` (or, without frontmatter, the code it describes) changed after the doc's last commit.

#### Scenario: Two-year-old architecture doc
- **WHEN** `docs/architecture.md` was last committed 2 years ago and `src/` has commits from last week
- **THEN** the findings report lists it as stale with both dates

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
