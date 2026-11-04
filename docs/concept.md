---
title: Concept
status: draft
last_reviewed: 2026-11-04
review_after_days: 120
owner: Eugen Waldschmidt
sources: [skills/]
---

# Concept

## Solution strategy

groma ships knowledge and procedure, not parsers. Each step is a Markdown skill that an agent executes; the agent already reads any language, so stack knowledge sits in reference tables the agent applies. Small POSIX shell scripts handle what must be deterministic: detection, freshness, config validation, change ids. An orchestrator skill runs seven sub-skills in eight steps and stores progress in `.groma/config.yaml`, so every run can resume or update.

## Key capabilities

| Capability | What it gives the user |
|---|---|
| Detect (`groma-detect`) | Greenfield or brownfield verdict with evidence |
| Survey (`groma-survey`) | Read-only code map, ADR and docs harvest, stale-doc check, findings report |
| Lay out (`groma-lay-out`) | A complete `docs/` tree with freshness frontmatter and MADR 4.0 ADRs |
| Methodology (`groma-methodology`) | OpenSpec, Spec Kit, BMAD or GSD set up non-interactively, plus the `<type><NNN>-<slug>` change convention |
| Skills (`groma-skills`) | Curated third-party skills per category, installed project-scoped |
| Agents (`groma-agents`) | One canonical `AGENTS.md` and pointer files for each agent |

## Crosscutting concepts

- **Additive writes.** groma creates files only at free paths plus `.groma/` and `docs/_groma/`. Proposed edits to existing files become snippets in the findings report.
- **Pending instead of failing.** Installs that cannot run go into `.groma/install.sh` and the step is marked `pending`.
- **Freshness.** Every generated doc has `last_reviewed`, `review_after_days` and `sources`; `freshness.sh` compares them with git history.
- **No credentials.** Scripts never connect to databases and never print secrets.

## Constraints

POSIX `sh` scripts that pass `shellcheck -s sh`; Markdown skills in the Agent Skills format; English artifacts; skill folders installable on their own via `npx skills`.
