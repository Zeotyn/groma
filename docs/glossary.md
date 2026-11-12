---
title: Glossary
status: draft
last_reviewed: 2026-11-12
review_after_days: 180
owner: Eugen Waldschmidt
sources: [README.md, skills/]
---

# Glossary

One term per row. Use these terms in code, docs and conversations. If a term means different things in different parts of the system, add one row per context.

| Term | Meaning | Context | Not to be confused with |
|---|---|---|---|
| groma | The skill suite; also the orchestrator skill `/groma` | whole project | the Roman surveying instrument it is named after |
| Greenfield | A folder with nothing to survey; groma interviews instead | detection | an empty git repo with history only (borderline, ask) |
| Brownfield | A folder with existing code to survey | detection | a project that already ran groma |
| Survey | Read-only analysis of an existing project, ending in a findings report | `groma-survey` | lay-out, which writes docs |
| Lay out | Creating or completing the `docs/` tree | `groma-lay-out` | survey |
| Doc slot | One of nine mandatory doc roles (index, vision, concept, architecture, data model, glossary, risks, code style, ADR) | `groma-lay-out` | a file; one existing file can fill a slot |
| Findings report | `docs/_groma/findings-<date>.md` with severities, evidence and snippets | survey | ADRs or risks |
| Snippet | A proposed edit to an existing file, written to the findings report instead of the file | additive writes | a patch groma applies |
| Additive write | Creating a file only at a free path, plus `.groma/` and `docs/_groma/` | all writing skills | editing existing files |
| Catalog | `catalog.yaml`: curated third-party skills grouped by category | `groma-skills` | a skill registry |
| Pending | A step whose commands are listed in `.groma/install.sh` for the user to run | config `steps` | failed |
| Change id | `<type><NNN>`, e.g. `c003`, prefix of every change name | conventions | an ADR number |
| Milestone | Change of type `m` grouping child changes via `Milestone: mNNN` | conventions | a release |
| Freshness | Whether a doc is fresh, stale or unknown, from frontmatter and git dates | survey | `status` in frontmatter |
| Review loop | `groma-loop`: propose, apply, verify, archive with review rounds by a second model | `groma-loop` | a code review by a person |
| Finding | One row of a reviewer's table (high, medium, low) that the author must fix or reject with a reason | `groma-loop` | a survey finding in the findings report |
| Lifecycle reminder | One line from `status.sh` naming the next action for an open change, a pending ADR, uncommitted files or unpushed commits | `groma-methodology` | a CI check |
| Living docs | Keeping `docs/` current inside every change: docs impact, ADR candidates, docs sync on archive | `groma-lay-out`, `groma-loop` | freshness, which only reports age |
| Docs impact | Docs whose `sources` changed in a change while the doc did not, plus decisions without an ADR | `docs-impact.sh` | stale docs |
| Docs gate | `docs.gate` level: `off`, `remind`, `review` (default), `strict` | config | the tests gate |
| ADR candidate | A design decision with alternatives (or `ADR: yes`) that needs an ADR with `origin: <change>#D<n>` | living docs | an accepted ADR |
| Code style | `docs/code-style.md`: tools table (config, check, fix), conventions, decisions | `groma-lay-out`, `groma-loop` | the rules inside a tool config, which the doc links but never copies |
| Style tool | A formatter or linter from `code-style-tools.md`, detected by its config file or chosen in the interview | `groma-survey`, `groma-lay-out` | a catalog skill |
| Convention | A style rule no tool enforces, tagged `EXTRACTED` (from configuration) or `INFERRED` (from a code sample) with a path | code style | a tool rule |
| Style drift | Tracked files that disagree with `.editorconfig` on indentation, line endings, final newline or trailing whitespace | `style-drift.sh` | data-model drift |
| Unchecked tool | A style tool with a config file whose check command runs in no CI workflow or project script | `style-drift.sh` | a missing tool |
| Integration strategy | `git.integrate`: how a change branch reaches the main branch, `rebase` (rebase, then fast-forward), `merge` (`--no-ff` merge commit) or `squash` (one commit named after the change); "merge" as a request means the configured strategy | git workflow | `git merge` the command |
| Main branch | The branch changes are integrated into: the remote's default branch, else `main`, else `master` | git workflow | the checked-out branch |
| Change branch | A branch named after the change id (`c007-cache`) that groma-loop creates when `branch_per_change` is true and never deletes | `groma-loop` | a feature branch with a free name |
| Git practice | What `git-practice.sh` reads from the main branch's history: merge commits, pull-request merges, `(#n)` subjects, conventional subjects, with a recommended strategy and commit style | `groma-detect` | the configured strategy, which the user picks |
| Push policy | `git.push`: `ask` (default), `auto` or `never`, for the main branch after integration | git workflow | the `unpushed` reminder of `status.sh` |
| Next action | The one step `next.sh` names for a project: the first rung of the ladder that applies, or nothing | `groma-methodology`, hooks, status line | the full reminder list of `status.sh` |
| Trusted publishing | npm publishing from the `release.yml` GitHub Actions workflow through OIDC, without a token; npmjs.com trusts `Zeotyn/groma` and that file name | releases, `scripts/release-check.sh` | provenance, which npm attaches to each version published this way |
| Ladder | The fixed, ordered list of rungs `next.sh` checks; the first match wins | `next.sh` | a priority score |
| Vendored copy | A byte-identical copy of a shared table, template or script inside a skill that reads it, listed in `scripts/shared-files.txt`, refreshed by `scripts/sync-shared.sh` | groma repository, ADR 0051 | the source, the only file a contributor edits |
| Procedure hand-off | A skill following another skill's `SKILL.md`, running a sibling's procedure or writing a sibling's script path into project files; the only allowed `../groma-<name>/` reference, listed in `scripts/handoffs.txt` | skills, ADR 0051 | a vendored copy, which the skill reads from its own folder |
