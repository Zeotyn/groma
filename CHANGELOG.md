# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and the project uses [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-11-04

### Added

- Initial groma skill suite (change C001, milestone M001): orchestrator `/groma` and six sub-skills for detection, read-only survey, docs layout, methodology setup, skill catalog and agent instructions.
- Change naming convention `<type><NNN>-<slug>` with next-id, check and roadmap scripts.
- Distribution as Claude Code plugin marketplace, via `npx skills`, manifests for Codex, Cursor and Gemini CLI, and `install.sh`.
- Review loop skill `groma-loop` (change C002, milestone M001): propose, apply, verify and archive with an independent reviewer model, reviewer `auto` selection, `autonomous` and `gated` modes, review records in the change folder.
- Lifecycle reminders: `status.sh` lists changes ready to archive, ticked without test changes or stale; AGENTS.md session-start line and optional Claude Code SessionStart hook.
- `review` and `reminders` sections in `.groma/config.yaml`.
- Test suite: structure checks, 105 script tests, never-overwrite invariant, headless agent evals on six fixtures.
