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
The suite SHALL follow SemVer with git tags and a `CHANGELOG.md` (Keep a Changelog). Plugin manifests, `package.json` and `skills/groma/VERSION` SHALL carry the same version. Updates SHALL work via `npx groma-cli update`, `npx skills update`, the Claude plugin update mechanism, and `install.sh --ref`.

#### Scenario: Version consistency
- **WHEN** a release tag `v0.2.0` is created
- **THEN** all manifests, `package.json` and `skills/groma/VERSION` declare `0.2.0`, and CI fails if any differs

#### Scenario: Project update through the CLI
- **WHEN** a project was initialized with groma 0.2.0 and the user runs `npx groma-cli@0.3.0 update`
- **THEN** the generated skill copies move to 0.3.0 and `initialized_with` reads `groma@0.3.0`

### Requirement: Open-source essentials
The repository SHALL contain `LICENSE` (MIT), `README.md` with an install matrix per agent, `CONTRIBUTING.md` explaining how to add catalog entries and detection patterns, and `AGENTS.md`.

#### Scenario: Contributor adds a stack pattern
- **WHEN** a contributor follows CONTRIBUTING.md to add a data-model source pattern
- **THEN** the change is a single table row plus an optional fixture, and CI validates it

### Requirement: npm package
groma SHALL be published to npm as `groma-cli`, runnable as `npx groma-cli <command>` without a global install and installing the binary `groma`, containing the CLI and the skill folders. The Claude plugin, `npx skills add` and `install.sh` SHALL stay supported install paths.

#### Scenario: Run without installing
- **WHEN** a user runs `npx groma-cli@0.2.1 init` in a fresh folder
- **THEN** npm fetches the package and the init starts, with no global install

### Requirement: Automated npm release from a tag
A pushed tag `v<version>` SHALL publish `groma-cli@<version>` to npm from GitHub Actions through npm trusted publishing (OIDC), without an npm token in the repository and without a person at a terminal. Before publishing, the release workflow SHALL check that the tag equals the version in every plugin manifest, `package.json` and `skills/groma/VERSION`, that `CHANGELOG.md` has a `## [<version>]` section, and that test levels 1 to 3 pass; if any check fails, nothing SHALL be published. After publishing, the workflow SHALL create a GitHub release whose notes are that CHANGELOG section.

#### Scenario: Release from a tag
- **WHEN** the maintainer pushes tag `v0.3.0` and every manifest, `package.json` and `skills/groma/VERSION` declare `0.3.0`, `CHANGELOG.md` has `## [0.3.0]`, and the tests pass
- **THEN** `groma-cli@0.3.0` is published to npm with provenance and a GitHub release `v0.3.0` carries the `[0.3.0]` CHANGELOG notes

#### Scenario: Tag and version differ
- **WHEN** the tag is `v0.3.1` but `package.json` declares `0.3.0`
- **THEN** the workflow fails before publishing and names the file whose version differs

#### Scenario: Release notes missing
- **WHEN** the tag is `v0.3.0` and `CHANGELOG.md` still holds the release under `[Unreleased]`
- **THEN** the workflow fails before publishing and says that `## [0.3.0]` is missing

#### Scenario: No token in the repository
- **WHEN** someone reads the release workflow and the repository secrets
- **THEN** the workflow authenticates to npm only through the OIDC `id-token` permission, and no `NPM_TOKEN` or `NODE_AUTH_TOKEN` is used

### Requirement: Marketplace bundles
The Claude Code marketplace SHALL offer, besides the full plugin `groma`, the bundles `groma-docs` (groma-detect, groma-survey, groma-lay-out) and `groma-loop` (groma-loop). Each bundle SHALL install only its skills, SHALL work without the CLI and without the other groma skills, and SHALL carry the same version as the full plugin.

#### Scenario: Docs bundle only
- **WHEN** a user runs `claude plugin install groma-docs@groma`
- **THEN** groma-detect, groma-survey and groma-lay-out are available, no other groma skill is installed, and a survey of a brownfield project produces its findings report

#### Scenario: Bundle versions
- **WHEN** a release tag `v0.4.0` is checked
- **THEN** every bundle manifest declares `0.4.0`, and the release check fails if one differs

