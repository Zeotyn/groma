---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
---

# Adopt the groma docs structure

## Context and Problem Statement

Documentation was missing, scattered or of unknown freshness. Humans and agents need one predictable place to find vision, concept, architecture, data model, terms, risks and decisions.

## Considered Options

* `docs/` with a fixed set of documents and freshness frontmatter (groma)
* Free-form documentation

## Decision Outcome

Chosen option: "`docs/` with a fixed set of documents and freshness frontmatter (groma)", because a fixed layout lets agents find context without searching, and frontmatter makes stale documents detectable.

### Consequences

* Good, because `docs/README.md` is a single entry point, and `review_after_days` plus `sources` let groma flag stale docs.
* Bad, because the fixed set may contain documents that stay short for small projects.

### Confirmation

Re-running `/groma` reports missing and stale documents in `docs/_groma/`.

## More Information

`docs/` is the product truth. Methodology folders (for example `openspec/`) hold change work and reference `docs/`.
