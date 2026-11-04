Milestone: m001

## Why

Starting or adopting a project with an AI coding agent costs hours of repetitive setup: choosing and initializing a spec methodology, installing the same favourite skills again, and writing vision, concept, architecture, data model and ADRs before real work can begin. Existing (brownfield) projects are worse: docs and ADRs are scattered or stale, and nobody knows what the code actually contains. **groma** is an open-source skill suite that lays out this groundwork once per project, the way the Roman groma surveyed a site before a city was built.

## What Changes

- New skill suite `groma`, distributed as one repository that works as a Claude Code plugin marketplace, via `npx skills add`, and via native manifests for Copilot, Codex, Gemini CLI and Cursor, with `install.sh` as fallback. MIT licensed.
- Orchestrator skill `/groma` that walks the user step by step through initialization and re-runs idempotently as an update mode.
- Automatic greenfield/brownfield detection.
- Methodology setup: OpenSpec (default), Spec Kit, BMAD, GSD or none, plus an optional workflow layer (e.g. superpowers) combinable with any methodology.
- Skill catalog with categories (design, writing, pragmatism, workflow, diagrams, discovery). The user picks per category; picks are stored per project in `.groma/config.yaml` and installed project-locally.
- Mandatory `docs/` structure for every project: `README.md`, `vision.md`, `concept.md`, `architecture.md`, `data-model.md`, `glossary.md`, `risks.md`, `adr/` (MADR 4.0), with freshness frontmatter.
- Brownfield discovery that never modifies existing files: knowledge graph (graphify), ADR and docs harvesting, stale-doc detection, stack-agnostic data-model extraction from code artifacts, retroactive ADRs with status `proposed`, and a findings report.
- Change naming convention from day one: every change is named `<type><NNN>-<slug>` with types `m` (milestone), `c` (change), `f` (fix), `s` (spike), `r` (refactor), `d` (docs), numbered per type with three digits (e.g. `m001-mvp`, `c004-export-csv`, `f002-null-on-empty`). Milestones bundle changes and fixes and are tracked in `docs/roadmap.md`. Types and format are configurable in `.groma/config.yaml`.
- One canonical `AGENTS.md` per project; `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md` and `.cursor/rules` point to it.
- Test harness: structure validation, shell script tests, a "no existing file changed" invariant check on fixture repos, and agent evals, wired into CI.

## Capabilities

### New Capabilities
- `orchestration`: the `/groma` entry point, step sequence, interview, idempotent update mode, graceful degradation when sub-skills are missing.
- `project-detection`: classify a target folder as greenfield or brownfield and report detected signals.
- `project-config`: `.groma/config.yaml` schema, versioning and migration hints.
- `skill-catalog`: categorized catalog of third-party skills, selection rules (single/multi, conditional on project traits), project-local installation per configured agent.
- `methodology-setup`: non-interactive initialization of the chosen spec methodology and optional workflow layer.
- `docs-scaffold`: creation and completion of the mandatory `docs/` tree, templates, freshness frontmatter, seed ADRs.
- `brownfield-discovery`: read-only analysis of existing projects: graph, ADR/docs harvest, freshness check, data-model extraction, findings report.
- `change-conventions`: naming, numbering and typing of changes; milestone bundling and roadmap tracking; enforcement through methodology rules and agent instructions.
- `agent-instructions`: canonical `AGENTS.md` and per-agent pointer files.
- `distribution`: repository layout, plugin manifests, `npx skills` compatibility, `install.sh`/`uninstall.sh`, versioning and updates.
- `suite-testing`: fixtures, test levels, invariants and CI gates for the suite itself.

### Modified Capabilities
<!-- none: no existing specs -->

## Impact

- New repository content: `skills/`, `catalog/`, `scripts/`, `templates/`, plugin manifests (`.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`, `gemini-extension.json`), `install.sh`, `tests/`, `.github/workflows/`, `LICENSE`, `README.md`, `AGENTS.md`.
- Runtime dependencies on target machines (installed or checked by scripts, never silently): Node ≥ 22 (`npx`), `git`; optional `uv` (graphify, Spec Kit).
- External projects referenced but not vendored: OpenSpec, Spec Kit, BMAD, GSD, superpowers, graphify, ponytail, i-have-adhd, impeccable, anti-ai-slop-writing, archify, vercel-labs/skills.
- Testable targets for maintainers: Claude Code and GitHub Copilot. Gemini CLI, Cursor and Codex are supported on a best-effort basis.
