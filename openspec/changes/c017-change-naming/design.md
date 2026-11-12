## Context

The convention lives in `skills/groma-methodology/references/conventions.md` and is copied into `methodologies.yaml` (OpenSpec and Spec Kit rules), the AGENTS.md template and the groma-methodology SKILL. Scripts: `lib-changes.sh` (types, `config_digits`, `list_changes`), `next-change-id.sh`, `check-conventions.sh`, `roadmap.sh` (generates the whole `docs/roadmap.md` from milestone proposals and `Milestone:` lines), `status.sh` (gate reminder from milestone tasks, codeless types `m` and `d`), `next.sh` (rung 5 from `status.sh`). The user approved the target rule on 2026-11-12 with four answers: drop `d`, add type words inside milestones, keep this repository on the old names until M4 ends, move the release gate into the roadmap.

## Goals / Non-Goals

**Goals:**
- Every change on a board is real work; milestones are planning text in the roadmap.
- Tools group changes by name prefix only.
- Short ids without padding.
- Existing projects keep working without a forced rename.

**Non-Goals:**
- Renaming archived changes, branches or ADR `origin` values.
- Changing this repository's active M004 changes.

## Decisions

### D1: The milestone is a roadmap section, not a change
`docs/roadmap.md` holds one hand-written `## M<N>: <title>` section per milestone with `**Goal:**` and a `**Release gate:**` checklist. Changes belong to a milestone by their `m<N>-` prefix.

Alternatives: keep umbrella changes with `skip_specs` (rejected: they never move on a board and need text parsing for grouping); a separate `milestones.yaml` (rejected: one more file format to parse, while the roadmap is already where people read milestones).

### D2: Type words inside a milestone
`m<N>-spike-`, `m<N>-fix-`, `m<N>-refactor-` carry the type; no type word means a change. Tools read the type from the word right after `m<N>-`.

Alternatives: only `-spike-` as in the first draft (rejected: a fix or refactor in a milestone would lose its type, and commit types and the codeless rule need it); allow `f`/`r` changes to join a milestone by a proposal line (rejected: brings back the text parsing this change removes).

### D3: Drop the `d` type
New changes have the types `m`, `c`, `f`, `s`, `r`. Docs are part of the change that causes them, as the docs gate already enforces. Old `d` names stay valid through the baseline.

Alternatives: keep `d` for docs-only work (rejected: zero `d` changes in 22 archived changes; README or planning work runs as `c` or without a change).

### D4: No zero padding
Numbers have no leading zeros; natural sort orders them. `conventions.changes.digits` is ignored and the validator warns. `next-change-id.sh` keeps its flags and prints `c17`; `next-change-id.sh m` prints the next free milestone number, the highest N among roadmap headings and `m<N>-` names (active and archived) plus one.

Alternatives: keep padding configurable (rejected: two formats for every tool to accept, for no ordering benefit).

### D5: `roadmap.sh` fills marked blocks only
Inside each milestone section, `roadmap.sh` replaces the text between `<!-- groma:changes m<N> -->` and `<!-- /groma:changes -->` with a table of that milestone's changes (name, active or archived, tasks done). Everything else in the file is the user's. A section without markers gets none added; `check-conventions.sh` reports it. For changes in the baseline it still reads `Milestone: mNNN` lines, so old projects keep their roadmap.

Alternatives: keep generating the whole file (rejected: goal and gate text would have to live elsewhere); generate a separate `roadmap.generated.md` (rejected: two files for one view).

### D6: Release gate from the roadmap
`status.sh` reports `M<N>  gate: <first open item>` for a milestone section with open `- [ ]` items under `**Release gate:**` and no active `m<N>-` change; `next.sh` rung 5 maps it as before. Codeless types for the test reminder become `s`, `m<N>-spike-` and `r` instead of `m` and `d`.

Alternatives: drop the gate reminder (rejected: F002 added it because the gate was forgotten); keep gate tasks in the last change of a milestone (rejected: no change owns the release).

### D7: Migration without renames
On the first run after the update, groma writes all existing change names to `.groma/conventions-baseline.txt` (when absent; otherwise it appends missing ones). `check-conventions.sh --suggest-migration` prints, read-only, a new name per old one (`c017-foo` → `c17-foo`, a child with `Milestone: m004` → `m4-foo`) and, per umbrella change, a roadmap section built from its proposal (title, goal line, open release-gate tasks, an empty marker block). groma puts these into the findings report; it never renames folders or edits existing files (ADR 0006).

Alternatives: rename automatically (rejected: breaks branches, links and ADR origins, and ADR 0006).

## Risks / Trade-offs

- [Two formats coexist in old projects] → the baseline and the `Milestone:` fallback keep tools working; the check tells new from old.
- [Hand-written roadmap without markers shows no change lists] → `check-conventions.sh` reports the missing block with the snippet.
- [Tools outside groma that parse `m001-*`] → none known; listed as breaking in the CHANGELOG.
