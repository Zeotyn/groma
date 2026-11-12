---
title: Concept
status: draft
last_reviewed: 2026-11-12
review_after_days: 120
owner: Eugen Waldschmidt
sources: [skills/]
---

# Concept

## Solution strategy

groma ships knowledge and procedure, not parsers. Each step is a Markdown skill that an agent executes; the agent already reads any language, so stack knowledge sits in reference tables the agent applies. Small POSIX shell scripts handle what must be deterministic: detection, freshness, config validation, change ids. An orchestrator skill runs its sub-skills in eight steps and stores progress in `.groma/config.yaml`, so every run can resume or update.

## Key capabilities

| Capability | What it gives the user |
|---|---|
| Detect (`groma-detect`) | Greenfield or brownfield verdict with evidence; integration strategy and commit style recommended from the git history |
| Survey (`groma-survey`) | Read-only code map, ADR and docs harvest, stale-doc check, style tools, conventions and editorconfig drift, findings report |
| Lay out (`groma-lay-out`) | A complete `docs/` tree (including `code-style.md`) with freshness frontmatter and MADR 4.0 ADRs; style tool configs and ADRs after the interview |
| Methodology (`groma-methodology`) | OpenSpec, Spec Kit, BMAD or GSD set up non-interactively, plus the `<type><NNN>-<slug>` change convention |
| Skills (`groma-skills`) | Curated third-party skills per category, installed project-scoped |
| Agents (`groma-agents`) | One canonical `AGENTS.md` and pointer files for each agent |
| Loop (`groma-loop`) | Each change proposed, applied, verified and archived with an independent reviewer model and a tests gate that includes the style checks; branched, committed per review unit, integrated and pushed by the git settings |
| Lifecycle reminders (`status.sh`) | One reminder per open change at session start: docs to update, verify and archive, untested ticks, milestone gates, stale work, pending ADRs; then uncommitted and unpushed work |
| Next action (`next.sh`) | The single next step, deterministic and without tokens, in the status line, in the agent's context at session start and after each answer (Claude Code hooks, shipped with the plugin) or with `npx groma-cli next` |

## Crosscutting concepts

- **Additive writes.** groma creates files only at free paths plus `.groma/` and `docs/_groma/`. Proposed edits to existing files become snippets in the findings report.
- **Pending instead of failing.** Installs that cannot run go into `.groma/install.sh` and the step is marked `pending`.
- **Freshness.** Every generated doc has `last_reviewed`, `review_after_days` and `sources`; `freshness.sh` compares them with git history. A source commit makes a doc stale only when it is newer than the doc and falls on a day after `last_reviewed`, so a review covers the commits of its own day.
- **Living docs.** Every change updates the docs whose `sources` it touches and records design decisions with alternatives as ADRs (`origin: <change>#D<n>`). `docs-impact.sh` reports what is missing; `docs.gate` (`off`, `remind`, `review`, `strict`) sets how hard groma-loop enforces it. A doc may be exempted with a task line `Docs: <path> unchanged, because <reason>`.
- **Code style.** Three layers: tool configs enforce what they can, `docs/code-style.md` links them and documents the conventions no tool enforces (each tagged `EXTRACTED` or `INFERRED` with a path), and ADRs hold the tool decisions. Agents reach the style through AGENTS.md, the methodology context and groma-loop's tests gate. The survey reports drift statically; no project tool runs during setup.
- **Git workflow.** The `git` section of the config decides once how changes are integrated (`rebase`, `merge`, `squash`), whether each change gets a branch, how commits are written and when groma pushes. AGENTS.md carries the rule for every agent, including those outside the loop: a request to "merge" means the configured sequence. groma-loop carries it out and stops on conflicts, a dirty tree or a rejected push instead of resolving, stashing or forcing.
- **Next action.** A fixed ladder picks one action from the reminders, so the user sees what to do next without asking. Hooks only display it; they never block, retry or prompt the agent. Each agent's hook support is data in `agents.yaml`; agents without a display-only channel rely on the AGENTS.md line.
- **Always-loaded budget.** Skill descriptions and the generated AGENTS.md are in the agent's context on every turn, so they stay short: at most 400 characters per description and 80 lines for the AGENTS.md template, enforced by the structure check (ADR 0071). Details go into skill bodies, references and `docs/`, which load on demand.
- **No credentials.** Scripts never connect to databases and never print secrets.

## Constraints

POSIX `sh` scripts that pass `shellcheck -s sh`; Markdown skills in the Agent Skills format; English artifacts; skill folders installable on their own via `npx skills`. The repository's own style is in [code-style.md](code-style.md).
