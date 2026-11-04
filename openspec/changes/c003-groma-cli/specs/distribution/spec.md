## ADDED Requirements

### Requirement: npm package
groma SHALL be published to npm as `groma`, runnable as `npx groma <command>` without a global install, containing the CLI and the skill folders. The Claude plugin, `npx skills add` and `install.sh` SHALL stay supported install paths.

#### Scenario: Run without installing
- **WHEN** a user runs `npx groma@0.2.0 init` in a fresh folder
- **THEN** npm fetches the package and the init starts, with no global install

## MODIFIED Requirements

### Requirement: Versioning and updates
The suite SHALL follow SemVer with git tags and a `CHANGELOG.md` (Keep a Changelog). Plugin manifests, `package.json` and `skills/groma/VERSION` SHALL carry the same version. Updates SHALL work via `npx groma update`, `npx skills update`, the Claude plugin update mechanism, and `install.sh --ref`.

#### Scenario: Version consistency
- **WHEN** a release tag `v0.2.0` is created
- **THEN** all manifests, `package.json` and `skills/groma/VERSION` declare `0.2.0`, and CI fails if any differs

#### Scenario: Project update through the CLI
- **WHEN** a project was initialized with groma 0.2.0 and the user runs `npx groma@0.3.0 update`
- **THEN** the generated skill copies move to 0.3.0 and `initialized_with` reads `groma@0.3.0`
