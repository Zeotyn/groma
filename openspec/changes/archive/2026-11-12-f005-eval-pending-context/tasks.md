## 1. Fix

- [x] 1.1 `tests/evals/assert.sh` (`empty`): accept the pending-methodology path (methodology pending, OpenSpec init in `install.sh`, code-style line in the findings snippet); keep the config check when `openspec/config.yaml` exists
- [x] 1.2 Re-assert the recorded 2026-11-12 `empty` run: exit 0, no FAIL; negative case with the line removed from the findings fails on "findings snippet has the code-style line"
- [x] 1.3 `scripts/test.sh` green
- [x] Docs: `docs/architecture.md` unchanged, because the eval levels and their roles stay the same; only one assertion accepts a path the spec already allows
- [x] Docs: `docs/code-style.md` unchanged, because the edit follows the documented shell conventions and adds none
