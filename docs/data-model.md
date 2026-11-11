---
title: Data model
status: draft
last_reviewed: 2026-11-11
review_after_days: 90
owner: Eugen Waldschmidt
sources: [skills/groma/templates/config.yaml, skills/groma-lay-out/templates/adr-template.md, skills/groma-skills/catalog.yaml, skills/groma-lay-out/references/doc-slots.md, skills/groma-methodology/references/conventions.md]
---

# Data model

Statements are tagged **EXTRACTED** (read from migrations, schema files or a schema dump) or **INFERRED** (derived from code, needs review). The physical schema is not copied here; see [Physical schema](#physical-schema).

groma has no database. Its persistent data are files it writes into target projects and the catalog it ships.

## Conceptual model

A **project config** records the choices of one groma run: the methodology, the agents and one skill pick per **catalog category**. Each pick refers to a **catalog skill**. Generated **docs** carry freshness frontmatter. **Changes** are named with a change id and may belong to a **milestone**. An **ADR** may record a decision of one change through its `origin`.

## Logical model

```mermaid
erDiagram
  PROJECT_CONFIG ||--o{ SKILL_PICK : records
  CATEGORY ||--o{ SKILL_PICK : "answered by"
  CATALOG_SKILL ||--o{ SKILL_PICK : "chosen as"
  CATEGORY }o--o{ CATALOG_SKILL : offers
  MILESTONE ||--o{ CHANGE : groups
  CHANGE ||--o{ ADR : "origin of"
```

| Entity | Key attributes | Relationships | Source | Tag |
|---|---|---|---|---|
| Project config | `schema`, `initialized_with`, `project.name`, `project.has_ui`, `project_type`, `methodology`, `workflow`, `agents`, `docs.gate` (off/remind/review/strict), `docs.adr_from` (design-alternatives/marked/off), `reminders.*` (`archive_when_done`, `stale_change_days`, `untested_tasks`, `uncommitted`, `unpushed`), `git.*` (`integrate` rebase/merge/squash, `branch_per_change`, `commits` conventional/free, `push` ask/auto/never), `steps.*` | has one skill pick per category | `skills/groma/templates/config.yaml` | EXTRACTED |
| Category | id, `select` (single/multi), `condition`, `recommended`, `options` | offers catalog skills | `skills/groma-skills/catalog.yaml` | EXTRACTED |
| Catalog skill | id, `source`, `ref`, `skills`, `claude_plugin`, `marketplace`, `install`, `post_install` | listed in categories | `skills/groma-skills/catalog.yaml` | EXTRACTED |
| Doc | `title`, `status`, `last_reviewed`, `review_after_days`, `owner`, `sources` | fills one doc slot | `skills/groma-lay-out/templates/docs/` | EXTRACTED |
| ADR | number `NNNN`, `status`, `date`, `evidence`, optional `origin` `<change>#D<n>` | records at most one change decision | `skills/groma-lay-out/templates/adr-template.md` | EXTRACTED |
| Change | id `<type><NNN>-<slug>`, optional `Milestone: mNNN` line | belongs to at most one milestone | `skills/groma-methodology/references/conventions.md` | EXTRACTED |

## Invariants

- A change id is never reused; numbers count per type and include archived changes.
- `workflow` is stored top-level, every other category under `skills.<category>`.
- `design` is `none` when `project.has_ui` is false.
- Every pick names an option of its category (checked by `validate-config.sh`).
- At most one ADR carries a given `origin`; it is `proposed` until its change is archived.

## Physical schema

The authoritative formats live in: `skills/groma/templates/config.yaml`, `skills/groma-skills/catalog.yaml`, validated by `skills/groma/scripts/validate-config.sh`.

## Drift

None found.
