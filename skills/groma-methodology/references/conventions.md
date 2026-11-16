# Change naming convention

Types, scripts, baseline and migration of the change naming convention. The rule text itself is in [naming-rule.md](naming-rule.md).

## Rule text

In [naming-rule.md](naming-rule.md); copy it as is.

## Names

`<type><N>-<slug>`: a type letter, a number without leading zeros, a kebab-case slug. Docs and summaries show the id in uppercase (`C4`, `M3`). A request for `C004-Export` becomes `c4-export`; say so.

| Type | Name | Number | Spec deltas | Why the type exists |
|---|---|---|---|---|
| change | `c<N>-<slug>` | per type, counts archived changes, never reused | yes | new or changed behavior |
| fix | `f<N>-<slug>` | per type | when the specified behavior changes | a defect is told apart from a feature on the board and in the commit type |
| spike | `s<N>-<slug>` | per type | no (`skip_specs: true`) | it ends in an ADR (`status: proposed`) or a follow-up change, never in production code |
| refactor | `r<N>-<slug>` | per type | no (`skip_specs: true`) | behavior stays the same, so no requirement changes |
| change of a milestone | `m<N>-<slug>` | N is the milestone; its changes share it | yes | the name alone groups the change under milestone N |
| spike, fix, refactor of a milestone | `m<N>-spike-<slug>`, `m<N>-fix-<slug>`, `m<N>-refactor-<slug>` | N is the milestone | as the type | the type word keeps the type inside a milestone |

There is no docs type: docs are updated in the change that causes them, which the docs gate checks. Custom types from `conventions.changes.types` behave like `c`. A `digits` key in older configs is ignored; the config check warns.

## Milestones

A milestone is not a change. It is a hand-written section of `docs/roadmap.md`, started from [../templates/roadmap-section.md](../templates/roadmap-section.md):

- heading `## M<N>: <title>`
- a `**Goal:**` line: the observable outcome
- a `**Release gate:**` checklist: what must be true before the release; `status.sh` and `next.sh` name its first open item once the milestone has changes and none of them is active (a planned milestone without changes stays silent). Nested items count like top-level ones; the list ends at the first line that is no list item, blank or indented
- a marker block `<!-- groma:changes m<N> -->` … `<!-- /groma:changes -->`: `roadmap.sh` writes the milestone's changes between the two lines and touches nothing else

Create `docs/roadmap.md` when the first milestone is planned. `next-change-id.sh m` prints the next free milestone number.

## Scripts

| Script | Purpose |
|---|---|
| `scripts/next-change-id.sh <type> --root <project>` | next free id, e.g. `c4`; for `m` the next free milestone number, e.g. `m5` |
| `scripts/check-conventions.sh --root <project>` | lists active names that violate the rule (with suggested names), duplicate ids and milestone sections without a marker block; exit 1 on problems. Archived names are never reported; active old names (`c017-export`) outside the baseline get an `INFO` line and do not fail |
| `scripts/check-conventions.sh --root <project> --suggest-migration` | prints new names for old ones and a roadmap section per old milestone change; changes nothing |
| `scripts/roadmap.sh --root <project>` | fills the marker blocks of `docs/roadmap.md` with each milestone's changes (name, state, tasks done of active changes); keeps CRLF and every byte outside the blocks |

## Brownfield baseline

When groma introduces the convention into a project with existing changes, write their names (one per line) to `<project>/.groma/conventions-baseline.txt`. They keep their names; the check skips them.

## Migration from `<type><NNN>-<slug>`

Projects set up with the old rule have zero-padded names (`c017-export`), milestones that are changes (`m003-v0-3`), children with a `Milestone: mNNN` line in `proposal.md`, and maybe `d` changes. Nothing is renamed, because names live on in branches, links and ADR `origin` values.

1. Write every existing change name, active and archived, that is not yet listed to `.groma/conventions-baseline.txt` (create the file when it is missing). Until then the check stays green for the old format: it prints an `INFO` line per active old name and ignores archived ones. The old names stay valid, old milestone changes keep their gate reminder, and their children stay grouped through the `Milestone:` line.
2. Run `check-conventions.sh --suggest-migration` and put its output into the findings report: a new name per active old one (`c017-export` → `c17-export`, a child of `m004` → `m4-<slug>`) and a roadmap section per old milestone change, built from its goal and its release-gate tasks.
3. The user decides: paste the sections into `docs/roadmap.md` (a file the old `roadmap.sh` generated is replaced by them), rename active changes or leave them. New changes follow the new rule either way.

## Mapping to other methodologies

| Methodology | Milestone | Change `c` / fix `f` |
|---|---|---|
| OpenSpec | section in `docs/roadmap.md`; its changes are folders `m<N>-*` | change folders |
| Spec Kit | section in `docs/roadmap.md` | feature folders `specs/c4-*`, `specs/m<N>-*` |
| BMAD | epic ↔ section in `docs/roadmap.md` | story |
| GSD | phase ↔ section in `docs/roadmap.md` | plan/task |
