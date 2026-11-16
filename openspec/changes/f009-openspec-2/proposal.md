Milestone: m004

## Why

OpenSpec 2.0 (released 2026-11-11) removed the `/opsx:*` slash commands: `/opsx:apply` is now the skill `/openspec-apply` (`$openspec-apply` in Codex), and the skills live in `.agents/skills/`. groma still prints `/opsx:` commands in the next action, in AGENTS.md and in groma-loop, so a project that ran `openspec update` gets commands that no longer exist. Projects set up with OpenSpec 1.x must keep working, because teams upgrade at different times.

## What Changes

- groma recognizes which OpenSpec generation a project has installed, from files in the project only (no `openspec --version` call), and prints the matching command form: `/opsx:<step>` for 1.x, `/openspec-<step>` for 2.x, and no command when it cannot tell.
- The command forms and their marker paths are data in the shared recipe file (`methodologies.yaml`), not code.
- The recipe's `touches` list includes `.agents/skills/openspec-*`, so a 2.x install counts as OpenSpec's own files.
- groma-agents and groma-loop name the OpenSpec workflow so that it is right for both generations.
- The init pin for new projects stays at OpenSpec 1.16.0 in this fix; moving new projects to 2.x is a separate change.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `next-action`: the long form prints the OpenSpec command of the generation the project has installed.
- `methodology-setup`: OpenSpec 1.x and 2.x installs are both recognized, with their command forms in the recipe data.

## Docs impact

`docs/architecture.md` (next.sh command form, recipe fields); `docs/concept.md` methodology row if it names `/opsx:`; ADR 0073 for recognizing the OpenSpec generation from project files.

## Impact

`skills/groma-methodology/methodologies.yaml`, `skills/groma-methodology/scripts/next.sh` (and `lib-changes.sh` if the lookup is shared), `skills/groma-agents/SKILL.md`, `skills/groma-loop/references/methodology-adapters.md`, `tests/scripts/next.bats`, structure check for the recipe fields if the CLI reads them (`bin/` / `lib/`).
