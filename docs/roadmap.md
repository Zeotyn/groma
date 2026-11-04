---
title: Roadmap
status: current
last_reviewed: 2026-11-04
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
- Status: active
- Progress: 3/6 done

| Id | Change | Status |
|---|---|---|
| C003 | `c003-groma-cli` | done |
| C004 | `c004-living-docs` | done |
| F001 | `f001-freshness-adrs` | done |
| F002 | `f002-status-milestone-gates` | active |
| F003 | `f003-freshness-reviewed` | active |
| F004 | `f004-npm-package-name` | active |

## M003 v0-3

- Goal: On the node-prisma and python-django fixtures, `/groma` produces `docs/code-style.md` with tool table and inferred conventions; on a greenfield TypeScript project it creates `.editorconfig`, Prettier and ESLint configs after the interview; groma-loop runs the style checks before review and integrates by the configured git strategy without merge commits by default. `v0.3.0` tagged, all test levels green.
- Status: active
- Progress: 0/3 done

| Id | Change | Status |
|---|---|---|
| C005 | `c005-code-style` | active |
| C006 | `c006-git-workflow` | active |
| C007 | `c007-next-action` | active |
