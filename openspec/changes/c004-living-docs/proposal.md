Milestone: m002

## Why

groma sets up `docs/` once, but nothing keeps it current. In this repository C002 added `groma-loop`, a new skill with six design decisions. Afterwards no doc mentions the skill and no ADR records those decisions. Every change has to update the docs it affects and record its decisions as ADRs. Otherwise `docs/` stops being the product truth that `openspec/config.yaml` says it is.

## What Changes

- New script `docs-impact.sh` in groma-lay-out. It is read-only and deterministic. For a change it compares the files changed since the change started with each doc's frontmatter `sources`. It reports two things: docs whose sources changed while the doc itself did not, and design decisions with considered alternatives that have no ADR. A task line `Docs: <path> unchanged, because <reason>` clears a doc.
- ADR candidates: each decision in a change's `design.md` that lists alternatives becomes an ADR with `status: proposed` and a new frontmatter key `origin: <change>#<decision>`. On archive it becomes `accepted`.
- Archive sync in groma-loop runs in this order: proposed ADRs with this change's `origin` become accepted, `last_reviewed` of every doc changed in the change is set to today, the ADR index is completed, and the roadmap is regenerated.
- Gate levels in `.groma/config.yaml`:
  - `docs.gate: off | remind | review | strict` (default `review`)
  - `docs.adr_from: design-alternatives | marked | off`
  - `review` makes open docs impact a high finding in groma-loop's verify.
  - `strict` additionally blocks archive.
- Methodology hooks: when groma creates `openspec/config.yaml`, it adds rules so every proposal has a `## Docs impact` section, every tasks file ends with a `Docs` group, and design decisions name their alternatives.
- `status.sh` reminders cover two cases: an active change whose tasks are all done but whose docs impact is open, and an ADR still `proposed` after its origin change was archived.
- AGENTS.md template: one line telling agents to update affected docs and record decisions in the same change.
- Dogfood: this repository's docs gain the C002 ADRs and `groma-loop` in architecture, concept and glossary.

## Capabilities

### New Capabilities
- `living-docs`: docs impact report, ADR candidates from design decisions, archive-time docs sync, gate levels.

### Modified Capabilities
- `review-loop`: verify includes the docs gate; archive runs the docs sync; `strict` blocks archive.
- `lifecycle-reminders`: docs-impact and pending-ADR reminders.
- `methodology-setup`: OpenSpec rules for docs impact, Docs task group and decision alternatives.
- `project-config`: `docs.gate` and `docs.adr_from` keys with validation.
- `agent-instructions`: AGENTS.md line on living docs.

## Impact

- New: `skills/groma-lay-out/scripts/docs-impact.sh`, `tests/scripts/docs-impact.bats`, fixture `living-docs`.
- Changed: `skills/groma-loop/SKILL.md`, `references/review-prompt.md`, `references/methodology-adapters.md`; `skills/groma-methodology/scripts/status.sh`, `references/methodologies.md`; `skills/groma/templates/config.yaml`, `scripts/validate-config.sh`; `skills/groma-lay-out/templates/adr-template.md`, `SKILL.md`; `skills/groma-agents/templates/AGENTS.md`; `skills/groma/references/upgrades.md`.
- Docs: new ADRs 0009 and later; `docs/architecture.md`, `docs/concept.md`, `docs/glossary.md`.
- Depends on F001 (`f001-freshness-adrs`), whose correct staleness and `broken` handling the gate builds on.
