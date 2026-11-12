## ADDED Requirements

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
