# Change naming convention

Single source of the rule text groma writes into AGENTS.md and methodology rules.

## Rule text (copy as is)

> Name every new change `<type><NNN>-<slug>` in lowercase kebab-case. Types: `m` milestone, `c` change, `f` fix, `s` spike, `r` refactor, `d` docs. Numbers are three digits, count per type, include archived changes and are never reused. A change that belongs to a milestone starts its `proposal.md` with `Milestone: mNNN`. Milestones, refactors and docs changes carry no spec deltas; spikes end in an ADR or a follow-up change, not in production code.

Replace the type list and digit count when `.groma/config.yaml` defines `conventions.changes`.

## Scripts

| Script | Purpose |
|---|---|
| `scripts/next-change-id.sh <type> --root <project>` | next free id, e.g. `c004` |
| `scripts/check-conventions.sh --root <project>` | lists violations (with suggested names) and duplicate ids; exit 1 on problems |
| `scripts/roadmap.sh --root <project>` | regenerates `docs/roadmap.md` from milestones and their children |

## Brownfield baseline

When groma introduces the convention into a project with existing changes, write their names (one per line) to `<project>/.groma/conventions-baseline.txt`. They keep their names; the check skips them.

## Mapping to other methodologies

| Methodology | Milestone `m` | Change `c` / fix `f` |
|---|---|---|
| OpenSpec | change folder `m001-*` with `skip_specs: true` | change folders |
| Spec Kit | (none, use `docs/roadmap.md`) | feature folders `specs/c004-*` |
| BMAD | epic | story |
| GSD | phase | plan/task |
