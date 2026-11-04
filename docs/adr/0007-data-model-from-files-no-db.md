---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-survey/references/data-sources.md, skills/groma-survey/scripts/dump-schema.sh, openspec/changes/c001-groma-suite/design.md]
---

# Derive the data model from files, never connect to a database

## Context and Problem Statement

Brownfield surveys need a data model. A live database connection puts credentials into the agent context and risks production systems.

## Considered Options

* Source hierarchy: migrations, schema files, ORM entities, API contracts, inference; optional user-run schema dump
* Direct database connection

## Decision Outcome

Chosen option: "Source hierarchy with optional user-run dump", because it needs no credentials or network. Statements are tagged `EXTRACTED` or `INFERRED`.

### Consequences

* Good, because no credentials, no production risk.
* Bad, because projects without migrations or schema files get an inferred model only.

### Confirmation

AGENTS.md rule: scripts never connect to databases and never print credentials.

## More Information

Derived by groma from existing code on 2026-11-04 (design decision D3); confirm or reject.
