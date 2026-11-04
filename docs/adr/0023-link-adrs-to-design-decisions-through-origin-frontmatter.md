---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-lay-out/scripts/docs-impact.sh, skills/groma-lay-out/templates/adr-template.md]
origin: c004-living-docs#D2
---

# Link ADRs to design decisions through an origin frontmatter key

## Context and Problem Statement

Design decisions in `design.md` should become ADRs, and a check must see which decisions still have none. None of C002's D1 to D6 had an ADR.

## Considered Options

* `origin: <change>#<Dn>` in the ADR frontmatter, with decision ids taken from `### D<n>:` headings in `design.md`
* Match ADR titles to decision titles
* Ask in every proposal which decisions need ADRs

## Decision Outcome

Chosen option: "`origin` frontmatter", because it survives title edits. In the `design-alternatives` mode a decision needs an ADR when its section has a line starting with `Alternatives`. The `marked` mode looks for a line `ADR: yes` instead. Title matching breaks when titles are edited. A question in every proposal is forgotten as soon as nobody asks.

### Consequences

* Good, because the link is explicit and machine-readable.
* Bad, because every ADR written from a decision must carry the key by hand.

### Confirmation

`tests/scripts/docs-impact.bats` checks that an ADR with a matching `origin` clears the `adr` line. ADRs 0009 to 0026 use the key.

## More Information

From design decision D2 of c004-living-docs. Related: ADR 0022.
