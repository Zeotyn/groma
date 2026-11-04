Milestone: m003

## Why

groma has no git policy. groma-loop records a base commit and leaves branching, committing, integrating and pushing to whoever drives the agent. In this repository that led to an unwanted merge commit (`47bf191`) because an orchestrator said "merge" while the project wants a linear history. The integration strategy has to be configured once, written where every agent reads it, and carried out by the loop.

## What Changes

- New `git` section in `.groma/config.yaml`:
  - `integrate: rebase | merge | squash` (default `rebase`)
  - `branch_per_change` (default `true`)
  - `commits: conventional | free` (default `conventional`)
  - `push: ask | auto | never` (default `ask`)
- New read-only script `git-practice.sh` in groma-detect. It reads the history and recommends an integration strategy and commit style: share of merge commits, "Merge pull request" subjects, `(#123)` squash subjects, and share of conventional subjects.
- The interview asks for the strategy:
  - Greenfield: recommend `rebase` and `push: ask`.
  - Brownfield: recommend what the history shows, with the evidence.
- AGENTS.md gets a "Git workflow" section generated from the config. It explains how to integrate, says that a request to "merge" means the configured strategy, says to stop on conflicts, and forbids force-push and deleting branches.
- groma-loop carries out the workflow:
  - Start: branch per change.
  - Apply: one commit per review unit after green tests and review.
  - Archive: an archive commit, then integration by strategy, then push by policy.
  - Escalation: on a rebase or merge conflict (after abort), and on a dirty working tree at start.
- Docs-impact base from C004: when on a change branch, the base becomes `git merge-base <main> <branch>`.
- Dogfood: this repository's `.groma/config.yaml` and AGENTS.md get the git section with `rebase` and `push: ask`.

## Capabilities

### New Capabilities
- `git-workflow`: git settings, history-based recommendation, integration strategies and safety rules.

### Modified Capabilities
- `review-loop`: branch, commit, integrate and push steps; new escalation causes.
- `agent-instructions`: generated "Git workflow" section in AGENTS.md.
- `orchestration`: interview question for the integration strategy.
- `project-config`: `git` keys with validation.

## Impact

- New: `skills/groma-detect/scripts/git-practice.sh`, `tests/scripts/git-practice.bats`, fixture histories (merge-PR, squash, linear).
- Changed: `skills/groma/templates/config.yaml`, `scripts/validate-config.sh`, `SKILL.md` (interview), `references/upgrades.md`; `skills/groma-agents/templates/AGENTS.md`; `skills/groma-loop/SKILL.md`, `references/methodology-adapters.md`; `skills/groma-lay-out/scripts/docs-impact.sh` (base, from C004).
- Docs impact: `docs/architecture.md` (loop git steps, new script), `docs/concept.md`, `docs/glossary.md` (integration strategy), ADR for D1 and D3; repository `AGENTS.md` and `.groma/config.yaml`.
- Depends on C004 (docs-impact base) and runs after C005 in M003.
