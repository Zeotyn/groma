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
| Runtime scripts | POSIX sh | Detection, git practice, freshness, style drift, docs impact, config validation, change ids, lifecycle status, reviewer calls, schema dump | `skills/*/scripts/` |
| Templates and references | Markdown, YAML | Docs, agent file and style config templates, stack tables (signals, data sources, ADR sources, style tools), skill catalog | `skills/*/templates/`, `skills/*/references/`, `skills/groma-skills/catalog.yaml` |
| Distribution manifests | JSON | Plugin and extension metadata per agent | `.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`, `gemini-extension.json`, `install.sh` |
| Test suite (not shipped) | sh, bats, Python via uv | Structure checks, script tests, invariant, evals | `scripts/test.sh`, `tests/` |

## Building blocks

- `groma`: orchestrator, owns `config.yaml` template, `check-prereqs.sh`, `validate-config.sh`.
- `groma-detect`: `detect.sh` plus `references/signals.md`; `git-practice.sh` recommends the integration strategy and commit style from the main branch's history.
- `groma-survey`: `freshness.sh`, `style-drift.sh` (tools from the lay-out table, `.editorconfig` drift, unchecked tools), `dump-schema.sh`, ADR and data-source tables, findings template.
- `groma-lay-out`: doc templates, `doc-slots.md`, `code-style-tools.md` with `templates/code-style/` (style setup) and `docs-impact.sh` (docs impact and ADR candidates of a change; on a change branch the base is the merge base with the main branch).
- `groma-methodology`: `next-change-id.sh`, `check-conventions.sh`, `roadmap.sh`, `status.sh` (lifecycle reminders), `next.sh` (the one next action, from `status.sh` output; share `lib-changes.sh`) and `next-stop.sh` (debounced display wrapper for agent stop hooks).
- `groma-loop`: runs one change through propose, apply, verify and archive with an independent reviewer; `resolve-reviewer.sh`, `review.sh`, review prompt and record templates.
- `groma-skills`: `catalog.yaml` and `references/install.md`.
- `groma-agents`: templates for `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `copilot-instructions.md`, `groma.mdc`; `references/git-strategies.md` holds the command sequences of the three integration strategies; `claude-stop-hook.json` and `statusline-snippet.sh` for the next action. Hook support per agent (event, config file, output format, status `stable`, `experimental` or `none`) is data in `skills/groma/agents.yaml`.

The orchestrator refers to siblings by relative path (`../groma-detect/`). A skill never calls another skill's scripts except through that documented sibling path, and every skill works alone. groma-survey reads groma-lay-out's `code-style-tools.md` the same way and degrades to "style tools not detected" when it is missing; groma-loop reads groma-agents' `git-strategies.md` and falls back to the "Git workflow" section of the project's AGENTS.md.

## Runtime view

`/groma` in init mode: detect → interview (style tools asked only when `style-drift.sh` finds none; integration strategy and push policy asked in git repositories, brownfield with the recommendation and evidence of `git-practice.sh`) → write `.groma/config.yaml` → methodology → skills → docs (survey first on brownfield; style setup from the interview, then the docs tree with `docs/code-style.md`) → agents → summary. After each step `steps.<name>` becomes `done`, `pending` or `skipped`. A later run validates the config and resumes at the first `pending` step.

`groma-loop` per change: propose → review rounds → apply per task group (tests gate with the code-style check commands, then review rounds on the diff with the code-style doc as project rules) → verify (plus the docs gate: every `docs-impact.sh` line is a high finding) → archive with spec sync and docs sync (proposed ADRs with this change's `origin` become accepted, `last_reviewed` of touched docs set, ADR index and roadmap updated). With `docs.gate: strict` archive waits until the report is empty. In a git repository the loop first requires a clean working tree, works on a branch named after the change, commits each review unit after its clean review, commits the archive, integrates with the configured strategy (rebase, merge or squash, the command sequence from `git-strategies.md`) and pushes the main branch by `git.push`. Before the integration the loop requires clean trees, records both refs and fast-forwards the main branch to its upstream; when the main branch is checked out in another worktree, the main-side commands run there (`git -C`). A conflicting integration is aborted, so both branches stay as they were, and escalated with the conflicting paths; a failure without conflicts stops without an abort; the loop never force-pushes, never moves the main branch by hand and never deletes branches. The main branch follows one rule for every script and skill (`git-strategies.md`, "Main branch").

`status.sh` at session start prints at most one reminder per active change (docs impact open, verify and archive, untested ticks, milestone gate, stale change), one line per ADR still `proposed` after its origin change was archived, and from local git state one line each for uncommitted files and for commits on the main branch not yet on its upstream. A milestone is at its gate when it has open tasks and no active change names it in a `Milestone:` line.

`next.sh` turns those reminders into one next action: the first rung of a fixed ladder (rebase or merge in progress, docs open, verify, uncommitted work, milestone gate, unpushed commits unless `git.push: never`, proposed ADR of an archived change, the active change with the newest commit). It checks the rebase or merge state itself and maps every other rung from one `status.sh` run. The result is cached in `.groma/.cache/next`, keyed on `HEAD`, `git status --porcelain` and the branch and remote refs, and invalidated when a file in the changes folder is newer than the cache. It reaches the user through display-only channels: the Claude Code status line (a snippet the user adds), the Claude Code Stop hook's `systemMessage` through `next-stop.sh`, which shows a line only when it changed or after `next.reshow_minutes`, the AGENTS.md "Session end" line and `npx groma-cli next`. No channel blocks the agent or feeds text back to it.

## Deployment

Distributed from GitHub (`Zeotyn/groma`) as a Claude Code / Copilot plugin marketplace, via `npx skills add`, as Codex, Cursor and Gemini manifests, through `install.sh`, and on npm as `groma-cli` (`npx groma-cli init`, command `groma`). Nothing runs as a service.

## Decisions

Architecture decisions are recorded in [adr/](adr/README.md).
