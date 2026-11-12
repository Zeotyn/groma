## 1. Tests first

- [ ] 1.1 bats: install each skill alone (copy its folder into a temp project) and run its scripts and a reference check; all but groma-detect fail before the refactor
- [ ] 1.2 Structure check: every pair in `scripts/shared-files.txt` is byte-identical; no skill file references `../groma-*/` except listed procedure hand-offs

## 2. Refactor

- [ ] 2.1 `scripts/shared-files.txt` with every source and consumer; `scripts/sync-shared.sh` (POSIX sh, shellcheck clean)
- [ ] 2.2 Vendor the files and switch skill text and scripts to the local copies
- [ ] 2.3 Procedure hand-offs: clear message and skip when the sibling skill is missing
- [ ] 2.4 `scripts/test.sh` green; tarball size before and after recorded here

## 3. Docs

- [ ] 3.1 `docs/architecture.md`, `CONTRIBUTING.md`; ADR for D1; CHANGELOG `[Unreleased]`
