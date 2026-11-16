# Change naming rule

The rule text groma writes into AGENTS.md and methodology rules. groma-agents carries a copy; types, scripts, baseline, migration and the mapping to other methodologies are in groma-methodology's `references/conventions.md`.

## Rule text (copy as is)

> Name every new change `<type><N>-<slug>` in lowercase kebab-case, the number without leading zeros. Types: `c` change, `f` fix, `s` spike, `r` refactor. Their numbers count per type, include archived changes and are never reused. A change that belongs to milestone N is named `m<N>-<slug>`, with a type word when it is a spike, fix or refactor: `m<N>-spike-<slug>`, `m<N>-fix-<slug>`, `m<N>-refactor-<slug>`. A milestone is not a change: it is a section `## M<N>: <title>` in `docs/roadmap.md` with a goal and a release-gate checklist. There is no docs type: docs are updated in the change that causes them. Spikes and refactors carry no spec deltas; spikes end in an ADR or a follow-up change, not in production code. Docs and summaries show ids in uppercase (`C4`, `M3`).

Replace the type list when `.groma/config.yaml` defines `conventions.changes.types`.
