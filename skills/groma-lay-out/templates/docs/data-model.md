---
title: Data model
status: draft
last_reviewed: {{today}}
review_after_days: 90
owner: {{owner}}
sources: [{{sources}}]
---

# Data model

Statements are tagged **EXTRACTED** (read from migrations, schema files or a schema dump) or **INFERRED** (derived from code, needs review). The physical schema is not copied here; see [Physical schema](#physical-schema).

## Conceptual model

{{conceptual: the main business objects and how they relate, in plain language, using terms from glossary.md}}

## Logical model

```mermaid
erDiagram
  {{ENTITY_A}} ||--o{ {{ENTITY_B}} : "{{relation}}"
```

| Entity | Key attributes | Relationships | Source | Tag |
|---|---|---|---|---|
| {{entity}} | {{attributes}} | {{relationships}} | {{path}} | EXTRACTED |

## Invariants

- {{invariant: rule that must always hold, e.g. "an order has at least one item"}}

## Physical schema

The authoritative schema lives in: {{physical: e.g. db/migrations/, prisma/schema.prisma}}

## Drift

{{drift: differences between sources, e.g. a column in a migration that the ORM does not map; "None found" if none}}
