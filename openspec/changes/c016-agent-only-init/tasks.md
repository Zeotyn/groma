## 1. Tests first

- [x] 1.1 `tests/scripts/materialize.bats`: the CLI's materialization scenarios against the script (create, unchanged replaced, edited kept, conflict for a foreign folder, removed skill deleted only when unchanged, `generatedBy` in SKILL.md, `--dry-run` writes nothing)
- [x] 1.2 Parity check: one fixture through `materialize.sh` and through `groma init --yes`; copied files and `.groma/generated.json` identical

## 2. Script

- [x] 2.1 `skills/groma/scripts/materialize.sh` per D1 (`sha256sum` or `shasum -a 256`); shellcheck clean
- [x] 2.2 `steps.skills_copy` in the config template and `validate-config.sh`

## 3. Skills and CLI

- [x] 3.1 groma SKILL: the default-yes question in step 7, update mode with `--update`, the plugin hint per D3 in the user's language
- [x] 3.2 `cli/init.js`: duplicate-plugin default "copy" plus the hint; node tests
- [x] 3.3 `upgrades.md` row 0.4.0; `scripts/test.sh` green

## 4. Docs

- [x] 4.1 README install section, `docs/architecture.md`, `docs/concept.md` (plus `docs/code-style.md`, `docs/data-model.md`, `docs/glossary.md`); ADRs 0057 (D1), 0058 (D2), 0059 (D3); ADR index. CHANGELOG `[Unreleased]`: CHANGELOG by integrator, not edited in this change
- [x] Docs: docs/vision.md unchanged, because the README change only describes the second install path; purpose, users and goals stay the same
