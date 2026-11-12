Milestone: m004

## Why

The README says "Every skill also works on its own", and the distribution spec says a skill installed alone with `npx skills add --skill` works standalone. Neither is true today: the skills reference about 30 files in sibling folders (`../groma-lay-out/references/code-style-tools.md`, `../groma/agents.yaml`, `../groma-agents/references/git-strategies.md`, …). Installed alone, `groma-survey` cannot find its style table and `groma-loop` cannot find its git strategies. Only `groma-detect` has no sibling dependency.

## What Changes

- Each skill carries its own copy of every shared file it reads (tables, templates, small scripts). One file stays the source of truth; a sync script `scripts/sync-shared.sh` copies it into every consumer, and the structure check fails when a copy differs from its source.
- Skill text and scripts read the local copy (`references/…`, `scripts/…`) instead of `../groma-*/`. Calls into another skill's *procedure* (for example groma loading groma-survey) stay, and degrade with a clear message when that skill is missing.
- A test installs each skill alone into a temporary folder and runs its scripts and a structure check there.
- No behavior change: the same tables, the same scripts, the same results.

## Capabilities

### New Capabilities
<!-- none: refactor (skip_specs: true); it makes the existing distribution requirement "npx skills with selective install" true -->

### Modified Capabilities
<!-- none -->

## Docs impact

`docs/architecture.md` (shared files and the sync rule); `CONTRIBUTING.md` (edit the source, run the sync); ADR for the vendoring decision.

## Impact

All skill folders that read sibling files; `scripts/sync-shared.sh`; `tests/structure/check.py`; a new bats file for standalone installs. Package size grows slightly.
