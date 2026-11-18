---
title: Roadmap
status: current
last_reviewed: 2026-11-16
review_after_days: 30
owner: Eugen Waldschmidt
sources: [openspec/changes]
---

# Roadmap

One section per milestone: goal, release gate and its changes. The sections are hand-written; `skills/groma-methodology/scripts/roadmap.sh` fills only the change lists between the `groma:changes` marker lines.

M1 to M4 were planned as milestone changes (`m001-v0-1` to `m004-v0-4`) with children that name them in a `Milestone:` line; these names are listed in `.groma/conventions-baseline.txt`. From M5 on a milestone exists only here, and its changes are named `m5-<slug>`.

Changes without a milestone are not listed here: `openspec list` and `skills/groma-methodology/scripts/status.sh` show the active ones, at present `c017-change-naming`. The Tasks column is the count at the last `roadmap.sh` run, for active changes only.

## M1: v0.1

**Goal:** `v0.1.0` tagged, all test levels green on all fixtures for Claude Code, Copilot manual protocol passed.

**Release gate:**
- [x] Test levels 1–4 green on all fixtures (Claude Code)
- [x] Copilot manual protocol passed
- [x] `v0.1.0` tagged, CHANGELOG released, README install matrix complete
- [x] `docs/roadmap.md` shows M001 complete

<!-- groma:changes m1 -->
| Change | State | Tasks |
|---|---|---|
| `c001-groma-suite` | archived | - |
| `c002-review-loop` | archived | - |
<!-- /groma:changes -->

## M2: v0.2

**Goal:** `npx groma-cli@0.2.1 init` works in an empty and in an existing project for Claude Code and Copilot, `groma-cli` is published on npm, all test levels green.

**Release gate:**
- [x] Test levels 1–4 green, including the CLI eval
- [x] `groma-cli@0.2.1` published on npm, `npx groma-cli@0.2.1 init --help` works from a clean machine
- [x] `v0.2.0` tagged, CHANGELOG released
- [x] `docs/roadmap.md` shows M002 complete

<!-- groma:changes m2 -->
| Change | State | Tasks |
|---|---|---|
| `c003-groma-cli` | archived | - |
| `c004-living-docs` | archived | - |
| `f001-freshness-adrs` | archived | - |
| `f002-status-milestone-gates` | archived | - |
| `f003-freshness-reviewed` | archived | - |
| `f004-npm-package-name` | archived | - |
<!-- /groma:changes -->

## M3: v0.3

**Goal:** On the node-prisma and python-django fixtures, `/groma` produces `docs/code-style.md` with tool table and inferred conventions; on a greenfield TypeScript project it creates `.editorconfig`, Prettier and ESLint configs after the interview; groma-loop runs the style checks before review and integrates by the configured git strategy without merge commits by default. `v0.3.0` tagged, all test levels green.

**Release gate:**
- [x] Test levels 1–4 green, including code-style evals on fixtures (2026-11-12: 8 of 8 after f005; `empty` re-asserted on the recorded run)
- [x] `v0.3.0` tagged, CHANGELOG released, npm package published
- [x] `docs/roadmap.md` shows M003 complete

<!-- groma:changes m3 -->
| Change | State | Tasks |
|---|---|---|
| `c005-code-style` | archived | - |
| `c006-git-workflow` | archived | - |
| `c007-next-action` | archived | - |
| `c008-release-workflow` | archived | - |
| `f005-eval-pending-context` | archived | - |
<!-- /groma:changes -->

## M4: v0.4

**Goal:** Every groma skill installed alone with `npx skills add Zeotyn/groma --skill <name>` passes its standalone test; the marketplace offers the bundles the spike confirms (at least `groma` and `groma-docs`); the eval run writes a token and cost report per fixture with a recorded baseline, and the always-loaded diet and the survey subagent are measured against it; the effect measurement compares one task with and without groma docs; with the plugin installed and the next action switched on, a new Claude Code session starts with the next action in the agent context and no settings file was written; groma talks to the user in the user's language; `/groma` with the plugin only copies the skills into the project by default and gives the same project result as `npx groma-cli init`. `v0.4.0` tagged and published through the release workflow, all test levels green.

**Release gate:** (also the open tasks of `m004-v0-4`, the last milestone that is a change)
- [x] Test levels 1–4 green, including the standalone-skill tests and the eval token report against the baseline (2026-11-18: levels 1–3 on 0.4.0; all 9 eval fixtures passed on main, 2026-11-16 and 2026-11-17)
- [x] `v0.4.0` tagged, CHANGELOG released, npm package published by the release workflow
- [x] `docs/roadmap.md` shows M004 complete

<!-- groma:changes m4 -->
| Change | State | Tasks |
|---|---|---|
| `c009-marketplace-bundles` | archived | - |
| `c010-token-report` | archived | - |
| `c011-always-loaded-diet` | archived | - |
| `c012-survey-subagent` | archived | - |
| `c013-effect-measurement` | archived | - |
| `c014-plugin-next-hooks` | archived | - |
| `c015-user-language` | archived | - |
| `c016-agent-only-init` | archived | - |
| `f007-eval-assertions` | archived | - |
| `f008-shellcheck-trap` | archived | - |
| `f009-openspec-2` | archived | - |
| `f010-eval-skill-source` | archived | - |
| `r001-vendor-shared-files` | archived | - |
| `s001-plugin-bundles-hooks` | archived | - |
<!-- /groma:changes -->
