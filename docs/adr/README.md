---
title: Architecture decision records
status: current
last_reviewed: 2026-11-04
review_after_days: 90
owner: Eugen Waldschmidt
sources: [docs/adr/]
---

# Architecture decision records

Format: [MADR 4.0](https://adr.github.io/madr/). File names: `NNNN-kebab-title.md`, numbers are never reused. Accepted ADRs are not edited; a new ADR supersedes them.

| ADR | Title | Status | Date |
|---|---|---|---|
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions | accepted | 2026-11-04 |
| [0002](0002-adopt-groma-docs-structure.md) | Adopt the groma docs structure | accepted | 2026-11-04 |

<!-- groma: list further ADRs here, including ADRs found elsewhere in the repository (with their path) -->
| [0003](0003-ship-self-contained-skill-folders.md) | Ship self-contained skill folders from one repository with per-agent manifests | accepted | 2026-11-04 |
| [0004](0004-stack-knowledge-in-reference-tables.md) | Keep stack knowledge in reference tables, not code | accepted | 2026-11-04 |
| [0005](0005-posix-sh-scripts.md) | Write runtime scripts in POSIX sh | accepted | 2026-11-04 |
| [0006](0006-additive-writes-only.md) | Never edit existing files in a target project | accepted | 2026-11-04 |
| [0007](0007-data-model-from-files-no-db.md) | Derive the data model from files, never connect to a database | accepted | 2026-11-04 |
| [0008](0008-four-level-test-strategy.md) | Test in four levels: structure, scripts, invariant, evals | accepted | 2026-11-04 |
| [0009](0009-separate-skill-for-review-loop-orchestration.md) | Run change orchestration in a separate skill, groma-loop | accepted | 2026-11-04 |
| [0010](0010-call-reviewer-clis-headless-through-review-sh.md) | Invoke reviewers through one headless, read-only wrapper script | accepted | 2026-11-04 |
| [0011](0011-reviewers-answer-in-a-validated-findings-table.md) | Require reviewer findings in a fixed Markdown table | accepted | 2026-11-04 |
| [0012](0012-limit-apply-reviews-to-the-task-group-diff.md) | Review apply work from the task group diff, not the whole repository | accepted | 2026-11-04 |
| [0013](0013-keep-status-script-in-groma-methodology.md) | Keep the status script in groma-methodology | accepted | 2026-11-04 |
| [0014](0014-offer-session-start-hook-in-local-settings.md) | Offer the status hook in local, uncommitted Claude settings | accepted | 2026-11-04 |
| [0015](0015-cli-installs-while-skills-stay-self-contained.md) | Let the CLI install skills while the skills stay self-contained | accepted | 2026-11-04 |
| [0016](0016-node-esm-cli-with-one-runtime-dependency.md) | Write the CLI in Node ESM with one runtime dependency | accepted | 2026-11-04 |
| [0017](0017-store-install-recipes-in-yaml-data-files.md) | Store install recipes in YAML data files shared by CLI and skills | accepted | 2026-11-04 |
| [0018](0018-track-generated-files-by-hash-for-ownership.md) | Track generated files by version and hash to decide ownership | accepted | 2026-11-04 |
| [0019](0019-offer-to-skip-claude-copies-when-plugin-is-installed.md) | Offer to skip Claude skill copies when the groma plugin is installed | accepted | 2026-11-04 |
| [0020](0020-share-step-state-between-cli-and-groma-skill.md) | Share step state between the CLI and the /groma skill | accepted | 2026-11-04 |
| [0021](0021-test-the-cli-with-unit-tests-bats-and-pack-check.md) | Test the CLI with unit tests, stubbed bats runs and a pack check | accepted | 2026-11-04 |
| [0022](0022-detect-docs-impact-from-changed-paths-and-doc-sources.md) | Detect docs impact by matching changed paths to doc sources | accepted | 2026-11-04 |
| [0023](0023-link-adrs-to-design-decisions-through-origin-frontmatter.md) | Link ADRs to design decisions through an origin frontmatter key | accepted | 2026-11-04 |
| [0024](0024-gate-docs-with-four-levels-default-review.md) | Gate docs with four levels and default to review | accepted | 2026-11-04 |
| [0025](0025-allow-docs-edits-inside-a-change-as-authored-work.md) | Treat docs edits inside a change as authored work | accepted | 2026-11-04 |
| [0026](0026-record-docs-exceptions-as-a-task-line.md) | Record docs exceptions as a task line with a reason | accepted | 2026-11-04 |
| [0028](0028-let-last-reviewed-cover-source-commits-of-that-day.md) | Let last_reviewed cover source commits up to the end of that day | proposed | 2026-11-04 |

Decision notes D1-D11 also live in `openspec/changes/c001-groma-suite/design.md` (change design, not ADRs).
