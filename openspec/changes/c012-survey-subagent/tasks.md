## 1. Tests first

- [x] 1.1 Eval assertion: findings report complete on the brownfield fixtures; summary handed back within ten lines

## 2. Survey

- [x] 2.1 groma-survey: map first, targeted reads, per-category caps in the report
- [x] 2.2 groma: start the survey as a subagent where supported, inline otherwise
- [ ] 2.3 Eval run; token difference against the C010 baseline recorded here; `scripts/test.sh` green (`scripts/test.sh` green; eval run pending (cost). `Agent` is now in the eval's allowed tools, so the headless run can spawn the survey subagent within the fixture budget; ADR 0069's confirmation stays partial until this run.)

## 3. Docs

- [x] 3.1 `docs/architecture.md`; ADR for D1; CHANGELOG `[Unreleased]` (architecture, concept, glossary and ADR 0069 done; CHANGELOG left to the integrator)
- [x] Docs: docs/code-style.md unchanged, because the new script follows the existing script, bats and Markdown conventions and adds no tool or rule
