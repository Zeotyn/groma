## 1. Tests first

- [x] 1.1 bats: install each skill alone (copy its folder into a temp project) and run its scripts and a reference check; all but groma-detect fail before the refactor
  - `tests/scripts/standalone.bats`, before the refactor (main 9d56a25): groma-detect ok; groma, groma-agents, groma-lay-out, groma-loop, groma-methodology, groma-skills, groma-survey not ok (29 unlisted sibling references); the hand-off list test not ok (groma-loop did not yet name `../groma-lay-out/SKILL.md`).
- [x] 1.2 Structure check: every pair in `scripts/shared-files.txt` is byte-identical; no skill file references `../groma-*/` except listed procedure hand-offs
  - `check.py shared` and `check.py handoffs` (hand-offs listed in `scripts/handoffs.txt`), unit tests in `tests/structure/test_check.py`.

## 2. Refactor

- [x] 2.1 `scripts/shared-files.txt` with every source and consumer; `scripts/sync-shared.sh` (POSIX sh, shellcheck clean)
- [x] 2.2 Vendor the files and switch skill text and scripts to the local copies
- [x] 2.3 Procedure hand-offs: clear message and skip when the sibling skill is missing
- [x] 2.4 `scripts/test.sh` green; tarball size before and after recorded here
  - `npm pack --dry-run`: before (main 9d56a25) 95,327 bytes packed, 279,110 unpacked, 96 files; after 98,682 bytes packed (+3.5 %), 379,500 unpacked, 116 files (19 vendored copies plus `install-consent.md`). The copies ship inside `skills/`; `scripts/sync-shared.sh`, `scripts/shared-files.txt` and `scripts/handoffs.txt` do not.

## 3. Docs

- [x] 3.1 `docs/architecture.md`, `CONTRIBUTING.md`; ADR for D1; CHANGELOG `[Unreleased]`
  - ADR 0051 (proposed); `docs/code-style.md` and `docs/glossary.md` updated too. CHANGELOG by integrator.
- [x] Docs: docs/concept.md unchanged, because it already states that skill folders install on their own; this change makes that true without changing the concept.
