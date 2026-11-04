## 1. Data files first

- [x] 1.1 `skills/groma/agents.yaml` (skill folders, home markers, npx skills ids, instruction files) and validator support in `tests/structure/check.py`
- [x] 1.2 `skills/groma-methodology/methodologies.yaml` for openspec, spec-kit, bmad, gsd, none; structure check
- [x] 1.3 Point `methodologies.md`, `install.md`, `groma-skills` and `groma-methodology` SKILL.md at the data files; remove command lines from prose

## 2. Package and test harness

- [x] 2.1 `package.json` (name `groma`, bin, `files`, engines node >= 22, dependency `yaml` pinned), version check covers it
- [x] 2.2 `node --test` setup under `cli/test/` and wiring into `scripts/test.sh` and CI
- [x] 2.3 CI step `npm pack --dry-run` asserting package contents

## 3. CLI core (tests with each task)

- [x] 3.1 Argument parsing, `--help`, `--version`, exit codes, Node version check
- [x] 3.2 Answer resolution: flags, interactive prompts (readline), `--yes`, no-TTY fallback, agent detection
- [ ] 3.3 Recipe rendering: methodology init and catalog installs per agent from the data files
- [ ] 3.4 Skill materialization with `generatedBy` and `.groma/generated.json`; conflict handling
- [ ] 3.5 Config writing from the template with step states; `agents_via_plugin` accepted by the validator
- [ ] 3.6 Command execution with ask-before-touching-existing-files, `--print`, `--dry-run`, `.groma/install.sh`

## 4. Commands

- [ ] 4.1 `init` end to end with summary and `/groma` hand-off
- [ ] 4.2 `update` with hash-based ownership, `--force`, removal of retired skills, pending steps
- [ ] 4.3 `status` (runs status.sh) and `doctor` (prereqs, config validation, generated file check)
- [ ] 4.4 Plugin detection for Claude

## 5. Integration

- [ ] 5.1 `groma` orchestrator: skip setup steps done by the CLI, recommend `npx groma init|update` for pending installs
- [ ] 5.2 bats end-to-end tests on fixtures with stubbed `npx`, `claude`, `openspec`, incl. the invariant
- [ ] 5.3 README: `npx groma init` as the first install path, other paths kept; CONTRIBUTING: CLI development
- [ ] 5.4 Eval: `groma init --yes --print` followed by `/groma` on the node-prisma fixture
