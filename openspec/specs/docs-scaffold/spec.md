# docs-scaffold Specification

## Purpose
Guarantees that every project has the same living `docs/` structure (vision, concept, architecture, data model, glossary, risks, ADRs), created for new projects and completed for existing ones without touching existing files.
## Requirements
### Requirement: Mandatory docs tree
Every project initialized by groma SHALL have `docs/README.md`, `docs/vision.md`, `docs/concept.md`, `docs/architecture.md`, `docs/data-model.md`, `docs/glossary.md`, `docs/risks.md`, `docs/code-style.md` and `docs/adr/` with `docs/adr/README.md`.

#### Scenario: Greenfield
- **WHEN** groma runs in a greenfield project
- **THEN** all mandatory docs exist afterwards, filled from the interview where answers exist and marked "Not yet documented" elsewhere

#### Scenario: Update adds the code-style doc
- **WHEN** a project initialized with groma 0.2 runs groma 0.3 in update mode and no file fills the code-style slot
- **THEN** `docs/code-style.md` is created and added to the findings report as new, and no other doc changes

### Requirement: Complete, never overwrite
If `docs/` exists, groma SHALL add only missing files and SHALL NOT modify, move or delete any existing file.

#### Scenario: Existing docs folder with different layout
- **WHEN** `docs/ARCHITECTURE.md` exists (uppercase) and `docs/vision.md` does not
- **THEN** groma creates `docs/vision.md`, does not create `docs/architecture.md`, and lists `docs/ARCHITECTURE.md` as the architecture document in `docs/README.md` if `docs/README.md` is newly created, otherwise in the findings report

### Requirement: Freshness frontmatter
Every doc created by groma SHALL start with YAML frontmatter containing `title`, `status`, `last_reviewed`, `review_after_days`, `owner` and `sources`. `sources` SHALL name code and configuration paths that outlive a change; it SHALL NOT name other docs or paths inside change folders such as `openspec/changes/`.

#### Scenario: Architecture doc frontmatter
- **WHEN** groma creates `docs/architecture.md` in a project with `src/`
- **THEN** its frontmatter has `status: draft`, today's date as `last_reviewed`, `review_after_days: 90` and `sources` listing the code paths described

#### Scenario: Decision taken in a change
- **WHEN** a doc explains a decision recorded in `openspec/changes/c005-x/design.md`
- **THEN** its `sources` list the code paths that implement the decision, and the doc links the ADR, not the change folder

### Requirement: ADRs in MADR 4.0 format
ADRs SHALL use the MADR 4.0 structure and file names `NNNN-kebab-title.md`. New projects SHALL receive seed ADRs `0001-record-architecture-decisions.md` and `0002-adopt-groma-docs-structure.md`. `docs/adr/README.md` SHALL list all ADRs with number, title, status and date.

#### Scenario: Seed ADRs
- **WHEN** groma creates `docs/adr/` in a project without ADRs
- **THEN** ADR 0001 and 0002 exist with status `accepted`, and the index lists both

#### Scenario: Numbering continues
- **WHEN** ADRs up to `0007` already exist
- **THEN** new ADRs start at `0008`

### Requirement: Data model doc levels
`docs/data-model.md` SHALL describe the conceptual and logical model and SHALL reference rather than copy the physical schema. If the project has no persistent data, the doc SHALL state "Not applicable" with a reason.

#### Scenario: CLI without storage
- **WHEN** no data sources are found and the user confirms there is no persistent data
- **THEN** `docs/data-model.md` contains "Not applicable: <reason>" and passes validation

### Requirement: Docs index
`docs/README.md` SHALL list every doc with purpose, status and `last_reviewed`, and SHALL be the entry point referenced from AGENTS.md.

#### Scenario: Index after scaffold
- **WHEN** the scaffold step completes
- **THEN** `docs/README.md` lists all mandatory docs and any optional docs present

