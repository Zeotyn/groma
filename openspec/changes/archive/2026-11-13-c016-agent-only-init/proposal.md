Milestone: m004

## Why

`/groma` already runs the whole init in the agent: detect, interview, config, methodology and catalog installs (with consent), docs, survey and AGENTS.md. Two steps still need `npx groma-cli`: copying the groma skills into the project's agent skill folders, and updating those copies later. Without the CLI the skills live only in the user's plugin, so a teammate who clones the repository gets neither `/groma` nor `groma-loop`. That breaks the promise that everything groma sets up lives in the project and is versioned with the code, and it leaves people who do not want the CLI with half a setup.

## What Changes

- New script `skills/groma/scripts/materialize.sh` (POSIX sh): copies every groma skill folder into the project skill folder of each selected agent, adds `metadata.generatedBy: groma@<version>` to each copied SKILL.md, and records every file with its SHA-256 in `.groma/generated.json`, in the same format and with the same rules as `groma init` and `groma update` (create, replace unchanged copies, keep and report edited copies, delete removed skills only when unchanged, never touch a folder groma did not create). `--update` and `--dry-run` modes.
- `/groma` copies the skills into the project **by default** when the CLI did not: one recommended-yes question ("Put the groma skills into the project so the team gets them with the repository?"). Update mode refreshes the copies with `materialize.sh --update` instead of telling the user to run `npx groma-cli update`.
- When the groma Claude plugin is also installed, the project copy is still made (it is what the team gets); groma tells the user how to switch the plugin off for this project so the skills do not appear twice. `groma init` follows the same default.
- Parity test: the same fixture set up by `/groma` with the plugin only and by `npx groma-cli init` yields the same `generated.json` and the same copied files.
- The CLI stays as the faster, deterministic path; both paths share the same rules, specified once.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `orchestration`: agent-side skill materialization by default; reuse of CLI setup no longer sends the user to the terminal for pending skill copies.
- `cli`: duplicate plugin detection defaults to copying the skills into the project.

## Docs impact

- `docs/architecture.md`: two equal init paths, one materialization rule set.
- `docs/concept.md`: the CLI is optional, not required for a complete, team-ready setup.
- `README.md`: install section says the agent path is complete.
- ADRs for D1 (shell script mirrors the CLI rules) and D3 (project copy by default, also with the plugin).

## Impact

- New: `skills/groma/scripts/materialize.sh`, `tests/scripts/materialize.bats`, a parity check.
- Changed: `skills/groma/SKILL.md` (step and update mode), `cli/init.js` (duplicate-plugin default), README, docs.
- Needs `sha256sum` or `shasum -a 256` on the machine (present on Linux and macOS).
