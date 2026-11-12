# Change naming convention

Defaults, scripts and baseline of the change naming convention. The rule text itself is in [naming-rule.md](naming-rule.md).

## Rule text

In [naming-rule.md](naming-rule.md); copy it as is.

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
