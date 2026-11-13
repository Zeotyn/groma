## 1. Fix

- [x] 1.1 `tests/evals/assert.sh`: `empty` accepts the pending code-style line in the findings report or in `.groma/install.sh`; `cli-node-prisma` looks for the update hint in the whole log
- [x] 1.2 Re-assert the recorded 2026-11-13 run of `empty` and `cli-node-prisma`: exit 0, no FAIL; negative cases with the content removed fail on the two assertions
- [x] 1.3 `scripts/test.sh` green
- [x] Docs: `docs/architecture.md` unchanged, because the eval levels and their roles stay the same
- [x] Docs: `docs/code-style.md` unchanged, because the edit follows the documented shell conventions
