---
title: Architecture
status: draft
last_reviewed: 2026-11-11
review_after_days: 90
owner: Eugen Waldschmidt
sources: [skills/, .claude-plugin/, .codex-plugin/, .cursor-plugin/, gemini-extension.json, install.sh, uninstall.sh, scripts/, tests/]
---

# Architecture

## System context

```mermaid
flowchart LR
  dev([Developer]) --> agent[AI coding agent]
  agent --> groma[groma skills]
  groma --> project[(Target project)]
  groma --> installers[Third-party installers: npx skills, claude plugin, openspec, uv]
  installers --> upstream[(Upstream skill repos on GitHub)]
```

A developer runs `/groma` inside an agent (Claude Code, Copilot, Gemini CLI, Cursor, Codex). The agent follows the skills, reads the target project, writes new files into it and calls third-party installers, or lists their commands in `.groma/install.sh`.

## Containers

| Container | Technology | Responsibility | Evidence |
|---|---|---|---|
| Skills | Markdown (Agent Skills format) | Procedure for each step | `skills/*/SKILL.md` |
| Runtime scripts | POSIX sh | Detection, freshness, style drift, docs impact, config validation, change ids, lifecycle status, reviewer calls, schema dump | `skills/*/scripts/` |
| Templates and references | Markdown, YAML | Docs, agent file and style config templates, stack tables (signals, data sources, ADR sources, style tools), skill catalog | `skills/*/templates/`, `skills/*/references/`, `skills/groma-skills/catalog.yaml` |
| Distribution manifests | JSON | Plugin and extension metadata per agent | `.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`, `gemini-extension.json`, `install.sh` |
| Test suite (not shipped) | sh, bats, Python via uv | Structure checks, script tests, invariant, evals | `scripts/test.sh`, `tests/` |

## Building blocks

- `groma`: orchestrator, owns `config.yaml` template, `check-prereqs.sh`, `validate-config.sh`.
- `groma-detect`: `detect.sh` plus `references/signals.md`.
- `groma-survey`: `freshness.sh`, `style-drift.sh` (tools from the lay-out table, `.editorconfig` drift, unchecked tools), `dump-schema.sh`, ADR and data-source tables, findings template.
- `groma-lay-out`: doc templates, `doc-slots.md`, `code-style-tools.md` with `templates/code-style/` (style setup) and `docs-impact.sh` (docs impact and ADR candidates of a change).
- `groma-methodology`: `next-change-id.sh`, `check-conventions.sh`, `roadmap.sh`, `status.sh` (lifecycle reminders; share `lib-changes.sh`).
- `groma-loop`: runs one change through propose, apply, verify and archive with an independent reviewer; `resolve-reviewer.sh`, `review.sh`, review prompt and record templates.
- `groma-skills`: `catalog.yaml` and `references/install.md`.
- `groma-agents`: templates for `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `copilot-instructions.md`, `groma.mdc`.

The orchestrator refers to siblings by relative path (`../groma-detect/`). A skill never calls another skill's scripts except through that documented sibling path, and every skill works alone. groma-survey reads groma-lay-out's `code-style-tools.md` the same way and degrades to "style tools not detected" when it is missing.

## Runtime view

`/groma` in init mode: detect → interview (style tools asked only when `style-drift.sh` finds none) → write `.groma/config.yaml` → methodology → skills → docs (survey first on brownfield; style setup from the interview, then the docs tree with `docs/code-style.md`) → agents → summary. After each step `steps.<name>` becomes `done`, `pending` or `skipped`. A later run validates the config and resumes at the first `pending` step.

`groma-loop` per change: propose → review rounds → apply per task group (tests gate with the code-style check commands, then review rounds on the diff with the code-style doc as project rules) → verify (plus the docs gate: every `docs-impact.sh` line is a high finding) → archive with spec sync and docs sync (proposed ADRs with this change's `origin` become accepted, `last_reviewed` of touched docs set, ADR index and roadmap updated). With `docs.gate: strict` archive waits until the report is empty.

`status.sh` at session start prints at most one reminder per active change (docs impact open, verify and archive, untested ticks, milestone gate, stale change), one line per ADR still `proposed` after its origin change was archived, and from local git state one line each for uncommitted files and for commits on the main branch not yet on its upstream. A milestone is at its gate when it has open tasks and no active change names it in a `Milestone:` line.

## Deployment

Distributed from GitHub (`Zeotyn/groma`) as a Claude Code / Copilot plugin marketplace, via `npx skills add`, as Codex, Cursor and Gemini manifests, through `install.sh`, and on npm as `groma-cli` (`npx groma-cli init`, command `groma`). Nothing runs as a service.

## Decisions

Architecture decisions are recorded in [adr/](adr/README.md).
