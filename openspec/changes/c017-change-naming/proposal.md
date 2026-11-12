## Why

The change naming convention groma writes into projects has three problems, seen in this repository's own M001 to M004:

1. A milestone is its own change (`m003-v0-3`) with no specs and no real tasks, only ticks for its children and a release gate. On a board or in `openspec list` it looks like work that never moves: it cannot be started, implemented or verified in any useful way. It is a planning document dressed up as a change.
2. Group membership hides in text: `status.sh`, `next.sh` and `roadmap.sh` grep a `Milestone: mNNN` line out of every `proposal.md` to group changes.
3. Three-digit padding gives nothing, because natural sort already orders `c2` before `c10`; it produces badges like `M001` and caps at 999.

The `d` (docs) type has not earned its place: none of the 22 archived changes here is a `d` change. Docs moved with the change that caused them, which the living-docs gate (C004) already enforces.

## What Changes

- **BREAKING (ID format):** names are `<type><N>-<slug>`, lowercase kebab-case, no zero padding (`c17-change-naming`, not `c017-…`). Docs and summaries show ids uppercase (`C17`, `M4`).
- **Milestones are no longer changes.** `m<N>-<slug>` means "a change that belongs to milestone N"; several changes share N (`m3-checkout`, `m3-payment`). A type word right after the milestone prefix carries the type: `m<N>-spike-<slug>`, `m<N>-fix-<slug>`, `m<N>-refactor-<slug>`; without a type word it is a change.
- `c`, `f`, `s`, `r` keep a running number per type that counts archived changes and is never reused. A standalone spike is `s<N>-<slug>`.
- **`d` is removed** as a type for new changes. Docs belong to the change that causes them; old `d` names stay valid through the baseline.
- **`docs/roadmap.md` holds the milestones**, hand-written: one `## M<N>: <title>` section each with a `**Goal:**` line and a `**Release gate:**` checklist. `roadmap.sh` fills only marked blocks (`<!-- groma:changes m<N> -->` … `<!-- /groma:changes -->`) with that milestone's changes, found by prefix; it no longer parses proposals or rewrites the whole file.
- **The release-gate reminder reads the roadmap:** `status.sh` and `next.sh` (rung 5) report `gate: <first open item>` for a milestone section with open release-gate items and no active `m<N>-` change.
- `next-change-id.sh` keeps its flags; its output drops the padding (`c17`), and `next-change-id.sh m` prints the next free milestone number (`m5`).
- `check-conventions.sh` checks the new format; duplicates are compared by `<type><N>` for `c`, `f`, `s`, `r` and by the full name for `m`. A new `--suggest-migration` prints new names for old ones and roadmap-section snippets for umbrella milestone changes.
- Commit types (C006) come from the prefix and the type word: `m<N>-` and `c` → `feat`, `-fix-` and `f` → `fix`, `-refactor-` and `r` → `refactor`, `-spike-` and `s` → `chore`.
- `conventions.changes.digits` is ignored with a validator warning; custom `types` stay.
- `templates/milestone-proposal.md` is replaced by `templates/roadmap-section.md`.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `change-conventions`: name format, types, numbering, milestones in the roadmap, roadmap tracking, configuration, check.
- `lifecycle-reminders`: the status report's milestone gate and codeless types come from the roadmap and the new prefixes.

## Docs impact

- `docs/glossary.md`: Milestone, change id.
- `docs/concept.md`, `docs/architecture.md`: change convention and roadmap.
- `README.md`: "Conventions groma sets up".
- ADRs for the design decisions with alternatives.

## Impact

- Scripts: `lib-changes.sh`, `next-change-id.sh`, `check-conventions.sh`, `roadmap.sh`, `status.sh`, `next.sh`; `validate-config.sh` (`digits` warning).
- Text: `references/conventions.md`, `methodologies.yaml`, `references/methodologies.md`, groma-methodology SKILL, AGENTS.md template, groma-loop `methodology-adapters.md` and groma-agents `git-strategies.md` (commit types), `upgrades.md`.
- Tests: `conventions.bats`, `next.bats`, `status.bats`, `git-integrate.bats`; fixture names in other bats files; evals `loop-openspec` (`c001-add-farewell` → `c1-add-farewell`) and its prompts and assertions.
- Existing projects: nothing is renamed automatically; the baseline keeps old names valid; umbrella milestones become roadmap sections through a findings snippet.
- This repository: M004 finishes under the old names; the new rule applies from M5 on.
