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

## Implementation notes

Deviations and choices made while building, 2026-11-16:

- **Old umbrella milestone, how scripts know one (D6, D7).** `is_umbrella` in `lib-changes.sh`: an `m<digits>-` name that is listed in the baseline, or whose number has a leading zero. The second half is not in the spec. It keeps a project working whose baseline was not written yet (the new format never has a leading zero), and it kept the F002 tests unchanged.
- **Codeless types (D6).** The type comes from `change_type`, so `m<N>-refactor-` gets no test reminder either, like `r`. The spec lists `s`, `m<N>-spike-` and `r` only; D2 says the codeless rule needs the type word.
- **`--suggest-migration` (D7).** It is its own mode: no check, exit 0. New names are printed for active changes only, because archived changes are never renamed (Non-Goals); sections are printed for every umbrella change, active and archived. The checklist of a section holds the tasks below a "Release gate" heading with their state, or the open tasks when there is no such heading. The title is the slug of the umbrella change.
- **Duplicates (D4).** Ids are compared as numbers, so `c005-a` from the baseline and a new `c5-b` collide. A duplicate full `m` name can only be an active and an archived change; the check asks for another slug.
- **Missing marker block.** `check-conventions.sh` counts it as a problem (exit 1), output line `MARKERS<TAB>M<N><TAB>…`.
- **Suggestions for unprefixed names.** `milestone-`, `release-`, `epic-`, `docs-` no longer map to a type (`m` is not a change type any more, `d` is gone); such names get a `c` id and keep the word in the slug.
- **`roadmap.sh` (D5).** A missing `docs/roadmap.md` is not created (the skill creates it from `templates/roadmap-section.md`). A block without a closing line stops the script with exit 1 before anything is written. `--today` is accepted and ignored. A file from the old generator (`generated_by: groma roadmap.sh`) without markers stays as it is and gets a hint on stderr. `docs/_groma/roadmap.md` is no longer written. AGENTS.md and `docs/code-style.md` name the marker block as an exception to the additive-writes rule (ADR 0066).
- **Roadmap gate (D6), changed after review round 1.** A section with an open gate item gets the line only when the milestone has at least one change (active or archived, by name or by a `Milestone:` line; an old umbrella change counts) and none is active. A planned milestone without any change stays silent, so it cannot hide push, ADR or apply in the next action. Nested checklist items count like top-level ones.
- **Short form of the next action.** A change of a milestone is named in full (`apply m3-checkout`, cut to 20 characters), because `m3` alone names the milestone. The roadmap gate is `gate M3`.
- **`next-change-id.sh m`** also reads old roadmap headings (`## M003 v0-3`) and umbrella names, so a migrated project does not reuse a milestone number.
- **Config.** `digits` and `d: docs` left the config template, this repository's config and the README example. A project whose config still lists `d` keeps it as a type; `upgrades.md` offers to remove it.
- **Spec Kit.** `methodologies.yaml` holds the naming rule only for OpenSpec (the Spec Kit append never had one); only that string changed.
- **This repository (task 5.2).** `.groma/conventions-baseline.txt` lists all 31 names, active and archived. `docs/roadmap.md` is now hand-written sections M1 to M4 built from `--suggest-migration`, with marker blocks. AGENTS.md and CONTRIBUTING.md say that names keep three digits until M004 is archived and that each new name goes into the baseline. `openspec/config.yaml` keeps the old rule text until then.
- **`upgrades.md`.** The row is filed under 0.4.0, the release `[Unreleased]` is collecting; the integrator moves it if this change ships later.
- **Evals (task 4.1).** Fixture, prompts and `assert.sh` renamed to `c1-add-farewell`; no eval was run (cost). The assertions were re-read against the new name: archive folder `*-c1-add-farewell`, branch `c1-add-farewell` (the conflict setup takes it from the folder name), commit subject `feat(c1-add-farewell): …` (type `feat` for `c<N>-` by the "Commit type" table).

Review round 1 (independent reviewer, 2026-11-16):

- **Old projects stay green.** `check-conventions.sh` never reports archived names, and an active name in the strict old format (`<known type or d>0NN-<slug>`) that is missing in the baseline gets an `INFO` line instead of a `VIOLATION`; exit 0. Other wrong formats (`c01-x`, uppercase, unprefixed) still fail. The CHANGELOG note for CI users is spelled out in task 5.4.
- **Suggestions.** A suggestion is never the reported name: `0` is no id (`c0-x` gets the next free id), an empty slug or a lone type word gets `<slug>` (`m3-fix-` → `m3-fix-<slug>`). In a duplicate, a name with a `VIOLATION` line is never the one kept when a conforming name exists, and it gets no second rename.
- **CRLF and bytes.** `ROADMAP_AWK` in `lib-changes.sh` holds the awk functions that read milestone headings and marker lines; `roadmap.sh`, `check-conventions.sh` and `status.sh` all use it, so the check and the script agree on what a marker is (a marker line with text after it is none for both). Lines written into a CRLF file end in CRLF; a file without a final newline gets none.
- **Roadmap table.** Archived rows show `-` in the Tasks column, so the file changes only while a change is active.
- **Commit type.** The table has a first row `m0<N>-` → `chore` for the padded umbrella milestone change.
