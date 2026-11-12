Milestone: m003

## Why

Every npm release of `groma-cli` needs the maintainer's terminal, because the npm account uses a passkey and an agent shell cannot answer it (`npm publish` fails with EOTP). The release step is the only part of a change's life that cannot run without a person at a specific machine. npm trusted publishing lets a GitHub Actions workflow publish through OIDC, with no token and no passkey prompt, so a pushed release tag is enough.

## What Changes

- New workflow `.github/workflows/release.yml`, triggered by a pushed `v*` tag:
  - checks that the tag equals the version in every manifest, `package.json` and `skills/groma/VERSION`, and that `CHANGELOG.md` has a `## [<version>]` section;
  - runs `scripts/test.sh` (levels 1 to 3);
  - publishes with `npm publish --provenance` through trusted publishing (`id-token: write`, npm 11.5.1 or newer), no `NODE_AUTH_TOKEN`;
  - creates a GitHub release whose notes are that CHANGELOG section.
- A small script `scripts/release-check.sh <tag>` holds the tag, version and CHANGELOG checks so they run the same in CI and locally.
- README gains a short "Releasing" section; the npm-side setup (trusted publisher `Zeotyn/groma`, workflow `release.yml`, direct publish allowed, tokens disallowed) is recorded there.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `distribution`: a new requirement for automated npm releases from a tag through trusted publishing.

## Docs impact

- `README.md`: "Releasing" section.
- `docs/architecture.md`: the release path in the distribution part.
- ADRs for D1 (trusted publishing instead of tokens or manual publish) and D2 (publish directly, not staged).

## Impact

- New: `.github/workflows/release.yml`, `scripts/release-check.sh`, `tests/scripts/release-check.bats`.
- No change to shipped skills or the CLI. Repo-level `scripts/` is not shipped.
- npm side: trusted publisher configured by the maintainer on npmjs.com (done 2026-11-12).
