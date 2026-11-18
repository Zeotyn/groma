## 1. Child changes

- [x] 1.1 S001 `s001-plugin-bundles-hooks` finished with an ADR or follow-up and archived
- [x] 1.2 R001 `r001-vendor-shared-files` implemented, verified and archived
- [x] 1.3 C009 `c009-marketplace-bundles` implemented, verified and archived
- [x] 1.4 C010 `c010-token-report` implemented, verified and archived, baseline recorded
- [x] 1.5 C011 `c011-always-loaded-diet` implemented, verified and archived
- [x] 1.6 C012 `c012-survey-subagent` implemented, verified and archived
- [x] 1.7 C013 `c013-effect-measurement` implemented, verified and archived
- [x] 1.8 C014 `c014-plugin-next-hooks` implemented, verified and archived
- [x] 1.9 C015 `c015-user-language` implemented, verified and archived
- [x] 1.10 C016 `c016-agent-only-init` implemented, verified and archived, parity test green
- [x] 1.11 C017 `c017-change-naming` implemented, verified and archived
- [x] 1.12 F009 `f009-openspec-2` implemented, verified and archived (OpenSpec 1.x and 2.x)
- [x] 1.13 F010 `f010-eval-skill-source` implemented, verified and archived (evals stop when a user-level groma skill shadows the checkout)

## 2. Release gate

- [x] 2.1 Test levels 1–4 green, including the standalone-skill tests and the eval token report against the baseline (2026-11-18: levels 1–3 green on main with the 0.4.0 versions, 550 bats including `standalone.bats` and `bundles.bats`, 78 structure checks, CLI tests. Level 4: all 9 fixtures passed on main, 7 in the joint run of 2026-11-16 and java-flyway and cli-node-prisma in the re-run of 2026-11-17 after the C012 fix; token reports against `baseline.tsv` recorded in C010, C011 and C012. Not re-run after F009, F010 and C013, which change only the printed OpenSpec command form (bats-tested) and eval scripts; the user agreed to count the existing runs.)
- [x] 2.2 `v0.4.0` tagged, CHANGELOG released, npm package published by the release workflow (2026-11-18: the first tag run stopped in the tests before publishing because release.yml did not install Claude Code for the C009 bundle tests; fixed in f57bf06, the unpublished tag moved there with the user's consent; npm `groma-cli@0.4.0` with provenance and the GitHub release from the CHANGELOG)
- [x] 2.3 `docs/roadmap.md` shows M004 complete
