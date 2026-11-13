---
title: Roadmap
status: current
last_reviewed: 2026-11-13
review_after_days: 30
owner: groma
sources: [openspec/changes]
generated_by: groma roadmap.sh
---

# Roadmap

Generated from change proposals. Edit the milestone proposals, then run `roadmap.sh` again.

## M001 v0-1

- Goal: `v0.1.0` tagged, all test levels green on all fixtures for Claude Code, Copilot manual protocol passed.
- Status: done
- Progress: 2/2 done

| Id | Change | Status |
|---|---|---|
| C001 | `c001-groma-suite` | done |
| C002 | `c002-review-loop` | done |

## M002 v0-2

- Goal: `npx groma-cli@0.2.1 init` works in an empty and in an existing project for Claude Code and Copilot, `groma-cli` is published on npm, all test levels green.
- Status: done
- Progress: 6/6 done

| Id | Change | Status |
|---|---|---|
| C003 | `c003-groma-cli` | done |
| C004 | `c004-living-docs` | done |
| F001 | `f001-freshness-adrs` | done |
| F002 | `f002-status-milestone-gates` | done |
| F003 | `f003-freshness-reviewed` | done |
| F004 | `f004-npm-package-name` | done |

## M003 v0-3

- Goal: On the node-prisma and python-django fixtures, `/groma` produces `docs/code-style.md` with tool table and inferred conventions; on a greenfield TypeScript project it creates `.editorconfig`, Prettier and ESLint configs after the interview; groma-loop runs the style checks before review and integrates by the configured git strategy without merge commits by default. `v0.3.0` tagged, all test levels green.
- Status: done
- Progress: 5/5 done

| Id | Change | Status |
|---|---|---|
| C005 | `c005-code-style` | done |
| C006 | `c006-git-workflow` | done |
| C007 | `c007-next-action` | done |
| C008 | `c008-release-workflow` | done |
| F005 | `f005-eval-pending-context` | done |

## M004 v0-4

- Goal: Every groma skill installed alone with `npx skills add Zeotyn/groma --skill <name>` passes its standalone test; the marketplace offers the bundles the spike confirms (at least `groma` and `groma-docs`); the eval run writes a token and cost report per fixture with a recorded baseline, and the always-loaded diet and the survey subagent are measured against it; the effect measurement compares one task with and without groma docs; with the plugin installed and the next action switched on, a new Claude Code session starts with the next action in the agent context and no settings file was written; groma talks to the user in the user's language; `/groma` with the plugin only copies the skills into the project by default and gives the same project result as `npx groma-cli init`. `v0.4.0` tagged and published through the release workflow, all test levels green.
- Status: active
- Progress: 5/10 done

| Id | Change | Status |
|---|---|---|
| C009 | `c009-marketplace-bundles` | done |
| C010 | `c010-token-report` | active |
| C011 | `c011-always-loaded-diet` | done |
| C012 | `c012-survey-subagent` | active |
| C013 | `c013-effect-measurement` | active |
| C014 | `c014-plugin-next-hooks` | done |
| C015 | `c015-user-language` | active |
| C016 | `c016-agent-only-init` | active |
| R001 | `r001-vendor-shared-files` | done |
| S001 | `s001-plugin-bundles-hooks` | done |

## Unassigned active changes

- `c017-change-naming`
