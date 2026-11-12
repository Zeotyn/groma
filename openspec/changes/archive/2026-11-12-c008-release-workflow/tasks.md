## 1. Tests first

- [x] 1.1 `tests/scripts/release-check.bats`: matching tag passes; tag not `v<semver>` fails; one manifest differing fails and names it; missing `## [<version>]` fails; `--notes` prints exactly that CHANGELOG section

## 2. Script and workflow

- [x] 2.1 `scripts/release-check.sh` per D3; shellcheck clean
- [x] 2.2 `.github/workflows/release.yml` per D1, D2: on `v*` tags; `contents: write`, `id-token: write`; release-check, test levels 1 to 3, `npm publish --provenance --access public` with npm 11.5.1+, GitHub release from `--notes`; no token
- [x] 2.3 `scripts/test.sh` green

## 3. Docs

- [x] 3.1 README "Releasing" section with the npm-side setup
- [x] 3.2 `docs/architecture.md` release path; ADRs for D1 and D2; ADR index; CHANGELOG `[Unreleased]`
- [x] Docs: `docs/vision.md` unchanged, because the README change documents the release procedure, not goals
- [x] Docs: `docs/code-style.md` unchanged, because the new script and tests follow the documented conventions and add no new one
