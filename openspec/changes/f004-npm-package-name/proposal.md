Milestone: m002

## Why

npm rejects the package name `groma`: "Package name too similar to existing packages growl, from2" (E403 on `npm publish`, 2026-11-04). M002 cannot ship `npx groma init` under that name. v0.2.0 is tagged on GitHub but was never published to npm.

## What Changes

- The npm package is named `groma-cli`. Users run `npx groma-cli <command>`; the installed binary stays `groma`.
- Every user-facing command hint (`npx groma ...`) in the CLI, the skills, README and specs becomes `npx groma-cli ...`.
- Unchanged: the product name groma, the plugin and skill names, and the version labels `groma@<version>` in `generatedBy` and `initialized_with`. They name the groma version, not the npm package.
- Released as 0.2.1. v0.2.0 stays a GitHub-only tag.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `distribution`: npm package name and update command.
- `cli`: command examples in scenarios.
- `orchestration`: the CLI commands `/groma` recommends.

## Impact

- `package.json`, `package-lock.json` (name), `cli/doctor.js`, `cli/init.js`, `cli/update.js`, `cli/test/doctor.test.js`
- `skills/groma/SKILL.md`, `skills/groma-skills/references/install.md`, `skills/groma/references/upgrades.md`
- `tests/evals/assert.sh`, `tests/evals/answers/cli-node-prisma.md`
- `README.md`, `openspec/specs/cli/spec.md` (Purpose line), M002 goal and task 2.2, C007 artifacts (`npx groma next`)

## Docs impact

- `docs/roadmap.md`: regenerated from the updated M002 goal.
- `docs/adr/0015-*.md`: unchanged, because its `npx groma ...` mention describes a rejected option, and an accepted ADR keeps its wording.
- ADRs: none planned. The name is forced by the registry and has no design alternatives worth recording.
