# distribution Specification

## Purpose
Makes groma installable and updatable from one public MIT-licensed repository through the Claude Code marketplace, `npx skills`, native manifests of other agents, and a fallback shell installer.
## Requirements
### Requirement: Claude Code marketplace
The repository SHALL be a valid Claude Code plugin marketplace exposing plugin `groma` with all groma skills.

#### Scenario: Install via marketplace
- **WHEN** a user runs `claude plugin marketplace add <owner>/groma` and `claude plugin install groma@groma`
- **THEN** `/groma` is available after reload

### Requirement: npx skills with selective install
The repository SHALL be installable with `npx skills add <owner>/groma`, and each groma skill SHALL be individually selectable with `--skill`.

#### Scenario: Install one sub-skill
- **WHEN** a user runs `npx skills add <owner>/groma --skill groma-lay-out -a claude-code -y`
- **THEN** only `groma-lay-out` is installed, and it works standalone

### Requirement: Other agents
The repository SHALL ship manifests for GitHub Copilot (via the Claude manifest), Codex, Gemini CLI and Cursor. Copilot SHALL be tested; Codex, Gemini CLI and Cursor SHALL be documented as best effort.

#### Scenario: Copilot CLI install
- **WHEN** a user runs `copilot plugin marketplace add <owner>/groma` and `copilot plugin install groma@groma`
- **THEN** the groma skills are available in Copilot

### Requirement: Fallback installer
`install.sh` SHALL detect installed agents, link (default) or copy (`--copy`) the skills into their user skill folders, support `--dry-run`, `--ref <tag>` and `--uninstall`, be idempotent, and never overwrite files it did not create.

#### Scenario: Foreign skill with same name
- **WHEN** `~/.claude/skills/groma` exists and is not a link created by groma
- **THEN** install.sh skips it, reports a conflict, and exits non-zero

#### Scenario: Re-run
- **WHEN** install.sh runs twice
- **THEN** the second run reports "already installed" for every skill and changes nothing

### Requirement: Versioning and updates
The suite SHALL follow SemVer with git tags and a `CHANGELOG.md` (Keep a Changelog). Plugin manifests SHALL carry the same version. Updates SHALL work via `npx skills update`, the Claude plugin update mechanism, and `install.sh --ref`.

#### Scenario: Version consistency
- **WHEN** a release tag `v0.2.0` is created
- **THEN** all manifests declare `0.2.0`, and CI fails if any differs

### Requirement: Open-source essentials
The repository SHALL contain `LICENSE` (MIT), `README.md` with an install matrix per agent, `CONTRIBUTING.md` explaining how to add catalog entries and detection patterns, and `AGENTS.md`.

#### Scenario: Contributor adds a stack pattern
- **WHEN** a contributor follows CONTRIBUTING.md to add a data-model source pattern
- **THEN** the change is a single table row plus an optional fixture, and CI validates it

