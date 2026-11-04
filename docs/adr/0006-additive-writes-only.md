---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [tests/invariant/checksum.sh, tests/invariant/checksum.bats, skills/groma-skills/references/install.md, openspec/changes/c001-groma-suite/design.md]
---

# Never edit existing files in a target project

## Context and Problem Statement

groma runs on repositories it does not own. Users must be able to trust that a run never damages existing work.

## Considered Options

* Additive writes: new paths plus `.groma/` and `docs/_groma/`; proposed edits become snippets in the findings report
* Edit existing files with confirmation

## Decision Outcome

Chosen option: "Additive writes", because it is safe to run and to re-run. Third-party installers that touch existing files run only after the user agrees; otherwise their commands go to `.groma/install.sh`.

### Consequences

* Good, because pre-existing files stay byte-identical.
* Bad, because users must apply snippets by hand.

### Confirmation

Checksum invariant compares SHA-256 of all pre-existing files before and after a run, in tests and evals.

## More Information

Derived by groma from existing code on 2026-11-04 (design decisions D4, D11); confirm or reject.
