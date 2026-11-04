---
title: Glossary
status: draft
last_reviewed: 2026-11-04
review_after_days: 180
owner: Eugen Waldschmidt
sources: [README.md, skills/]
---

# Glossary

One term per row. Use these terms in code, docs and conversations. If a term means different things in different parts of the system, add one row per context.

| Term | Meaning | Context | Not to be confused with |
|---|---|---|---|
| groma | The skill suite; also the orchestrator skill `/groma` | whole project | the Roman surveying instrument it is named after |
| Greenfield | A folder with nothing to survey; groma interviews instead | detection | an empty git repo with history only (borderline, ask) |
| Brownfield | A folder with existing code to survey | detection | a project that already ran groma |
| Survey | Read-only analysis of an existing project, ending in a findings report | `groma-survey` | lay-out, which writes docs |
| Lay out | Creating or completing the `docs/` tree | `groma-lay-out` | survey |
| Doc slot | One of eight mandatory doc roles (index, vision, concept, architecture, data model, glossary, risks, ADR) | `groma-lay-out` | a file; one existing file can fill a slot |
| Findings report | `docs/_groma/findings-<date>.md` with severities, evidence and snippets | survey | ADRs or risks |
| Snippet | A proposed edit to an existing file, written to the findings report instead of the file | additive writes | a patch groma applies |
| Additive write | Creating a file only at a free path, plus `.groma/` and `docs/_groma/` | all writing skills | editing existing files |
| Catalog | `catalog.yaml`: curated third-party skills grouped by category | `groma-skills` | a skill registry |
| Pending | A step whose commands are listed in `.groma/install.sh` for the user to run | config `steps` | failed |
| Change id | `<type><NNN>`, e.g. `c003`, prefix of every change name | conventions | an ADR number |
| Milestone | Change of type `m` grouping child changes via `Milestone: mNNN` | conventions | a release |
| Freshness | Whether a doc is fresh, stale or unknown, from frontmatter and git dates | survey | `status` in frontmatter |
