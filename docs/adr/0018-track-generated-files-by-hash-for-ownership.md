---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [cli/skills.js, cli/update.js, cli/config.js]
origin: c003-groma-cli#D4
---

# Track generated files by version and hash to decide ownership

## Context and Problem Statement

The CLI materializes SKILL.md copies in a project and must refresh them later without overwriting user edits.

## Considered Options

* `metadata.generatedBy: groma@<version>` in every materialized SKILL.md, plus `.groma/generated.json` mapping each generated path to its SHA-256

No alternatives were recorded.

## Decision Outcome

Chosen option: "Version marker plus hash map", because a file is groma's to replace only if it is listed there and its current hash matches. Everything else is user-owned. Copies are committed with the project so the team gets the same version, like OpenSpec's.

### Consequences

* Good, because user edits to generated skills survive an update.
* Bad, because a user edit makes the file permanently user-owned until `--force` is used.

### Confirmation

`cli/test/update.test.js` and `cli/test/skills.test.js` test the ownership rules. `tests/invariant/checksum.sh` checks the never-overwrite invariant.

## More Information

From design decision D4 of c003-groma-cli. No alternatives were recorded. Related: ADR 0006.
