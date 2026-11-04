# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed

- `status.sh` no longer says "nothing open" while work is open (fix F002): a milestone with open tasks and no active child gets `gate: <first open task>`, and uncommitted files and commits on the main branch not yet on its upstream get one line each, from local git state only. Turn the new lines off with `reminders.uncommitted` and `reminders.unpushed`.
- `freshness.sh` no longer reports docs as stale when their sources changed on the day of `last_reviewed` (fix F003). A source commit now counts only when it is newer than the doc and falls on a later day; the stale reason names `last_reviewed`. Docs without `last_reviewed` behave as before.

## [0.2.1] - 2026-11-04

### Fixed

- The npm package is now `groma-cli`, because npm rejects the name `groma` as too similar to existing packages (fix F004). Run `npx groma-cli init`; the installed command stays `groma`. 0.2.0 was tagged but never published to npm.

## [0.2.0] - 2026-11-04

### Added

- npm CLI `groma` (change C003): `npx groma init` copies the skills into each agent's project skill folder, runs the methodology init and catalog installs and writes `.groma/config.yaml`, `.groma/generated.json` and `.groma/pending.json`; `update` refreshes copies and re-runs pending steps; `status` and `doctor` complete the set. Requires Node.js 22+.
- Config key `agents_via_plugin` for agents whose skills come from an installed plugin.
- Shared data files `skills/groma/agents.yaml` and `skills/groma-methodology/methodologies.yaml`, read by both the CLI and the skills.
- `/groma` skips the config, methodology and skills steps when the CLI marked them `done`.
- Living docs (change C004): `docs-impact.sh` in groma-lay-out reports docs whose sources a change touched without updating them and design decisions without an ADR; config keys `docs.gate` (`off`, `remind`, `review`, `strict`) and `docs.adr_from`; ADR frontmatter `origin: <change>#D<n>`; groma-loop adds the report to verify as high findings and runs a docs sync on archive; `status.sh` reminds about open docs impact and ADRs still proposed after archive; OpenSpec rules for a Docs impact section, a Docs task group and decision alternatives; a living-docs line in the AGENTS.md template.
- ADRs 0009 to 0026 for the decisions of C002, C003 and C004.

### Changed

- Install recipes moved out of skill logic into `methodologies.yaml` and `agents.yaml`.

### Fixed

- `freshness.sh` no longer reports ADRs as stale after code changes; an ADR with `status: proposed` older than `--adr-days` (default 30) is stale instead (fix F001). Sources inside the docs folder are ignored. Missing sources and sources inside `openspec/changes/` are reported as `broken`; the summary line gains a trailing `broken=<n>` field.

## [0.1.0] - 2026-11-04

### Added

- Initial groma skill suite (change C001, milestone M001): orchestrator `/groma` and six sub-skills for detection, read-only survey, docs layout, methodology setup, skill catalog and agent instructions.
- Change naming convention `<type><NNN>-<slug>` with next-id, check and roadmap scripts.
- Distribution as Claude Code plugin marketplace, via `npx skills`, manifests for Codex, Cursor and Gemini CLI, and `install.sh`.
- Review loop skill `groma-loop` (change C002, milestone M001): propose, apply, verify and archive with an independent reviewer model, reviewer `auto` selection, `autonomous` and `gated` modes, review records in the change folder.
- Lifecycle reminders: `status.sh` lists changes ready to archive, ticked without test changes or stale; AGENTS.md session-start line and optional Claude Code SessionStart hook.
- `review` and `reminders` sections in `.groma/config.yaml`.
- Test suite: structure checks, 105 script tests, never-overwrite invariant, headless agent evals on six fixtures.
