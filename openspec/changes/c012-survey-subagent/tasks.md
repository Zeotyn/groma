## 1. Tests first

- [x] 1.1 Eval assertion: findings report complete on the brownfield fixtures; summary handed back within ten lines

## 2. Survey

- [x] 2.1 groma-survey: map first, targeted reads, per-category caps in the report
- [x] 2.2 groma: start the survey as a subagent where supported, inline otherwise
- [ ] 2.3 Eval run; token difference against the C010 baseline recorded here; `scripts/test.sh` green (`scripts/test.sh` green; eval run pending (cost). `Agent` is now in the eval's allowed tools, so the headless run can spawn the survey subagent within the fixture budget; ADR 0069's confirmation stays partial until this run.)
- [x] 2.4 Fix after the 2026-11-16 eval run: the subagent replies with the filled report instead of writing it (Claude Code refuses report files from subagents), the main session writes it unchanged and runs `report-check.sh`, which now also names a missing `generated_by` line and empty sections (diagnosis in design.md)

## 3. Docs

- [x] 3.1 `docs/architecture.md`; ADR for D1; CHANGELOG `[Unreleased]` (architecture, concept, glossary and ADR 0069 done; CHANGELOG left to the integrator)
- [x] Docs: docs/code-style.md unchanged, because the new script follows the existing script, bats and Markdown conventions and adds no tool or rule
- [x] Docs: docs/concept.md unchanged, because its survey row ("in a subagent where the agent has one") still holds after the 2.4 fix; who writes the report is recorded in docs/architecture.md and ADR 0069
- [x] Docs: docs/vision.md unchanged, because README.md was changed by other M004 changes after this change was planned (commit 4910ce3), not by C012
