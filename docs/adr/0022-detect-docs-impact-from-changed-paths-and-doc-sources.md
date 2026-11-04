---
status: proposed
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-lay-out/scripts/docs-impact.sh, tests/scripts/docs-impact.bats]
origin: c004-living-docs#D1
---

# Detect docs impact by matching changed paths to doc sources

## Context and Problem Statement

Nothing connects a change to the docs it affects. After C002, `architecture.md`, `concept.md` and `glossary.md` do not mention `groma-loop`. The data for a check exists: frontmatter `sources` map docs to code, and `git diff` lists what a change touched.

## Considered Options

* `docs-impact.sh [--base <ref>] [--gate] <change-dir>`: prefix-match each changed path against each non-ADR doc's `sources`
* Ask the reviewer model to judge docs impact
* Map impact by doc slot (architecture follows any code)

## Decision Outcome

Chosen option: "`docs-impact.sh` with path matching", because it is deterministic and cheap enough to run in every verify and status call. The default base is the parent of the commit that added `<change-dir>/proposal.md`, else `HEAD`. The frontmatter parsing from F001 is copied into the script because skills are self-contained. A reviewer judgement is not repeatable and costs a round. Slot mapping is too coarse and would flag every doc on every change.

### Consequences

* Good, because the result is repeatable and needs no model call.
* Bad, because docs without `sources` are invisible to the check.

### Confirmation

`tests/scripts/docs-impact.bats` runs the report on the `living-docs` fixture. The frontmatter parsing is copied from `freshness.sh`.

## More Information

From design decision D1 of c004-living-docs. Related: ADR 0003.
