---
status: accepted
date: 2026-11-16
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/scripts/check-conventions.sh, skills/groma-methodology/references/conventions.md, skills/groma/references/upgrades.md, .groma/conventions-baseline.txt, tests/scripts/conventions.bats]
origin: c017-change-naming#D7
---

# Migrate change names by baseline and suggestions, never by renaming

## Context and Problem Statement

Projects set up with the old rule hold names like `c017-foo`, umbrella changes like `m004-v0-4` and children with a `Milestone:` line. The new rule (ADR 0062 to 0065) would turn all of them into violations.

## Decision Drivers

* Existing projects keep working without a forced rename
* groma never edits or renames existing files (ADR 0006)
* Branches, links and ADR `origin` values keep pointing at real names

## Considered Options

* Write the existing names to the conventions baseline and print suggestions with `check-conventions.sh --suggest-migration`
* Rename automatically

## Decision Outcome

Chosen option: "baseline plus read-only suggestions", because a rename breaks branches, links and ADR origins, and ADR 0006 forbids it.

Details:
- On the first run after the update, groma writes all existing change names to `.groma/conventions-baseline.txt`, creating the file or appending the missing names.
- `--suggest-migration` prints a new name per active old one (`c017-foo` → `c17-foo`, a child of `m004` → `m4-foo`, with the type word for fixes, spikes and refactors) and, per umbrella change, a roadmap section built from its goal and release-gate tasks with an empty marker block. Archived changes get no new name.
- Until the baseline is written the check stays green: archived names are never reported, and an active name in the old format `<type>0NN-<slug>` gets an `INFO` line that names the baseline and `--suggest-migration`. A project that runs the check in CI does not turn red by updating groma.
- groma puts this output into the findings report. The user pastes sections and renames, or leaves everything.
- Scripts tell an old umbrella change from a change of a milestone by the baseline, or by a zero-padded number, which the new format never has.
- This repository lists all its names in the baseline and finishes M004 under the old names; the new rule applies from M5.

### Consequences

* Good, because nothing breaks on update, and the check tells old names from new ones.
* Bad, because two formats coexist in old projects until the old changes are archived.
* Bad, because the `Milestone:` fallback and the umbrella gate stay in the scripts for those projects.

### Confirmation

`tests/scripts/conventions.bats`: baseline accepts padded and `d` names, an old project without a baseline exits 0 with INFO lines, archived names are not reported, `--suggest-migration` output for names and umbrella milestones, no file changed. `sh skills/groma-methodology/scripts/check-conventions.sh --root .` prints `conventions: ok` in this repository.

## Pros and Cons of the Options

### Rename automatically

* Good, because one format remains.
* Bad, because it breaks branches, links and ADR origins, and ADR 0006.

## More Information

From design decision D7 of c017-change-naming. Related: ADR 0006, ADR 0062, ADR 0066.
