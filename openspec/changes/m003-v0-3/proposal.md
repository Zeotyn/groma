## Why

v0.3 makes groma projects consistent in how code is written: the style is detected or set up once, documented in `docs/code-style.md`, and followed by every agent that changes the project.

## What Changes

Milestone only; behavior is specified in the child changes.

**Goal:** On the node-prisma and python-django fixtures, `/groma` produces `docs/code-style.md` with tool table and inferred conventions; on a greenfield TypeScript project it creates `.editorconfig`, Prettier and ESLint configs after the interview; groma-loop runs the style checks before review and integrates by the configured git strategy without merge commits by default. `v0.3.0` tagged, all test levels green.

**Scope:**
- In: everything specified in `c005-code-style`, `c006-git-workflow`, `c007-next-action` and `c008-release-workflow`.
- Out: running project linters during the read-only survey; editing existing build files to add style tools; style rules for prose.

**Child changes:**

| Id | Change | Status |
|---|---|---|
| C005 | `c005-code-style` | active |
| C006 | `c006-git-workflow` | active (after C005) |
| C007 | `c007-next-action` | active (after C006) |
| C008 | `c008-release-workflow` | archived 2026-11-12 (npm release from a tag) |

## Capabilities

### New Capabilities
<!-- none: milestone without spec deltas (skip_specs: true) -->

### Modified Capabilities
<!-- none -->

## Impact

Tracked in `docs/roadmap.md` (regenerate with `roadmap.sh`). Starts after M002 (C004 living docs is a prerequisite).
