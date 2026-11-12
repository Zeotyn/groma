# Change naming rule

The rule text groma writes into AGENTS.md and methodology rules. groma-agents carries a copy; scripts, baseline and the mapping to other methodologies are in groma-methodology's `references/conventions.md`.

## Rule text (copy as is)

> Name every new change `<type><NNN>-<slug>` in lowercase kebab-case. Types: `m` milestone, `c` change, `f` fix, `s` spike, `r` refactor, `d` docs. Numbers are three digits, count per type, include archived changes and are never reused. A change that belongs to a milestone starts its `proposal.md` with `Milestone: mNNN`. Milestones, refactors and docs changes carry no spec deltas; spikes end in an ADR or a follow-up change, not in production code.

Replace the type list and digit count when `.groma/config.yaml` defines `conventions.changes`.
