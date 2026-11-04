## Why

First public release of groma: a usable, tested skill suite that initializes greenfield and brownfield projects for Claude Code and GitHub Copilot, installable via the Claude marketplace and `npx skills`.

## What Changes

Milestone only; behavior is specified in the child changes.

**Goal:** `v0.1.0` tagged, all test levels green on all fixtures for Claude Code, Copilot manual protocol passed.

**Scope:**
- In: everything specified in `c001-groma-suite`.
- Out: npm wrapper (`npx groma`), live database access, tested support for Codex, Gemini CLI and Cursor (best effort only).

**Child changes:**

| Id | Change | Status |
|---|---|---|
| C001 | `c001-groma-suite` | active |

## Capabilities

### New Capabilities
<!-- none: milestone without spec deltas (skip_specs: true) -->

### Modified Capabilities
<!-- none -->

## Impact

Tracked in `docs/roadmap.md` once groma's own docs exist (dogfooding task 9.3 in C001).
