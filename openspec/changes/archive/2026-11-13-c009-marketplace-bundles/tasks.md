## 1. Tests first

- [x] 1.1 Test: install each bundle into a temporary plugin dir and list its skills; structure check for bundle manifests and versions

## 2. Bundles

- [x] 2.1 Marketplace entries and bundle manifests in the layout from S001
- [x] 2.2 `scripts/release-check.sh` and the version check cover every bundle manifest
- [x] 2.3 `scripts/test.sh` green

## 3. Docs

- [x] 3.1 README "Install" bundle table; `docs/architecture.md`
- [x] 3.2 CHANGELOG `[Unreleased]` (CHANGELOG by integrator)
- [x] Docs: docs/vision.md unchanged, because the README change adds install commands for bundles and no change to who groma is for or what it does.
- [x] Docs: docs/code-style.md unchanged, because the new tests follow the existing conventions (bats under `tests/scripts/` with `helpers.bash`, pytest for `check.py`) and add no tool or rule.
