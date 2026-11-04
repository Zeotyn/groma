## Why

v0.2 makes setup deterministic: a terminal command installs everything a project needs, so agents spend their turn on survey and docs instead of installs they may not be allowed to run.

## What Changes

Milestone only; behavior is specified in the child changes.

**Goal:** `npx groma@0.2.0 init` works in an empty and in an existing project for Claude Code and Copilot, `groma` is published on npm, all test levels green.

**Scope:**
- In: everything specified in `c003-groma-cli`, `f001-freshness-adrs` and `c004-living-docs`.
- Out: porting skill logic to Node, a global install requirement, Node < 22.

**Child changes:**

| Id | Change | Status |
|---|---|---|
| F001 | `f001-freshness-adrs` | archived |
| C003 | `c003-groma-cli` | active |
| C004 | `c004-living-docs` | active (after F001) |

## Capabilities

### New Capabilities
<!-- none: milestone without spec deltas (skip_specs: true) -->

### Modified Capabilities
<!-- none -->

## Impact

Tracked in `docs/roadmap.md` (regenerate with `roadmap.sh`).
