---
title: Architecture decision records
status: current
last_reviewed: 2026-11-04
review_after_days: 90
owner: Eugen Waldschmidt
sources: [docs/adr/]
---

# Architecture decision records

Format: [MADR 4.0](https://adr.github.io/madr/). File names: `NNNN-kebab-title.md`, numbers are never reused. Accepted ADRs are not edited; a new ADR supersedes them.

| ADR | Title | Status | Date |
|---|---|---|---|
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions | accepted | 2026-11-04 |
| [0002](0002-adopt-groma-docs-structure.md) | Adopt the groma docs structure | accepted | 2026-11-04 |

<!-- groma: list further ADRs here, including ADRs found elsewhere in the repository (with their path) -->
| [0003](0003-ship-self-contained-skill-folders.md) | Ship self-contained skill folders from one repository with per-agent manifests | accepted | 2026-11-04 |
| [0004](0004-stack-knowledge-in-reference-tables.md) | Keep stack knowledge in reference tables, not code | accepted | 2026-11-04 |
| [0005](0005-posix-sh-scripts.md) | Write runtime scripts in POSIX sh | accepted | 2026-11-04 |
| [0006](0006-additive-writes-only.md) | Never edit existing files in a target project | accepted | 2026-11-04 |
| [0007](0007-data-model-from-files-no-db.md) | Derive the data model from files, never connect to a database | accepted | 2026-11-04 |
| [0008](0008-four-level-test-strategy.md) | Test in four levels: structure, scripts, invariant, evals | accepted | 2026-11-04 |

Decision notes D1-D11 also live in `openspec/changes/c001-groma-suite/design.md` (change design, not ADRs).
