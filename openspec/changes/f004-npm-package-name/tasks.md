## 1. Tests first

- [x] 1.1 `scripts/test.sh` pack check: fail unless `package.json` has `name: groma-cli` and `bin.groma`
- [x] 1.2 `cli/test/doctor.test.js` and `tests/evals/assert.sh`: expect `npx groma-cli update`

## 2. Implementation

- [x] 2.1 `package.json` and `package-lock.json`: name `groma-cli`, bin stays `groma`
- [x] 2.2 `cli/doctor.js`, `cli/init.js`, `cli/update.js`: hints say `npx groma-cli`
- [x] 2.3 `skills/groma/SKILL.md`, `skills/groma-skills/references/install.md`, `skills/groma/references/upgrades.md`, `tests/evals/answers/cli-node-prisma.md`: `npx groma-cli`
- [x] 2.4 `README.md`, `openspec/specs/cli/spec.md` Purpose line, M002 goal and task 2.2, C007 artifacts: `npx groma-cli`
- [x] 2.5 `scripts/test.sh` green, `npm publish --dry-run` shows `groma-cli`

## 3. Docs

- [x] 3.1 CHANGELOG `[0.2.1]`: Fixed entry; versions bumped to 0.2.1
- [x] 3.2 `docs/roadmap.md` regenerated
- [x] 3.3 `docs/architecture.md`: distribution line names the npm package
- [x] Docs: docs/adr/0015-cli-installs-while-skills-stay-self-contained.md unchanged, because its `npx groma` mention describes a rejected option and accepted ADRs keep their wording
- [x] Docs: docs/concept.md unchanged, because it does not name the npm package
- [x] Docs: docs/glossary.md unchanged, because it does not name the npm package
- [x] Docs: docs/risks.md unchanged, because the version bump adds no risk
- [x] Docs: docs/vision.md unchanged, because it does not name the npm package
