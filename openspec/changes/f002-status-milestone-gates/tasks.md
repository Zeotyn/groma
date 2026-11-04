## 1. Tests first

- [x] 1.1 `tests/scripts/status.bats`: milestone at gate (first open task, 60-char cut), milestone with active child (no gate line), gate replaces stale, uncommitted count, unpushed count against a local bare upstream, no upstream → no line, toggles off, "nothing open" only without any line
- [x] 1.2 `tests/scripts/validate-config.bats`: `reminders.uncommitted` and `reminders.unpushed` accept true/false, reject other values with line number

## 2. Implementation

- [x] 2.1 `status.sh`: milestone references and gate reminder per D1; header comment updated
- [x] 2.2 `status.sh`: repository lines per D2, toggles per D3
- [x] 2.3 `config.yaml` template and `validate-config.sh`; runtime on this repository under 300 ms, else note the measurement here. Measured: 0.70 s (3 runs, 0.70–0.73 s); the unchanged script took 0.56–0.64 s, so F002 adds about 0.1 s. The base cost was already over the target before this change.
- [x] 2.4 `shellcheck -s sh` and `scripts/test.sh` green

## 3. Docs

- [x] 3.1 `docs/architecture.md` (status.sh row) and `docs/data-model.md` (config keys); proposed ADR for D1 with `origin: f002-status-milestone-gates#D1` (ADR 0027); `docs/concept.md` and `docs/glossary.md` reminder rows updated too
- [x] 3.2 CHANGELOG `[Unreleased]`: Fixed entry
- [x] Docs: docs/vision.md unchanged, because only README.md (npm name, F004) matches its sources, and the vision does not change
- [x] 3.3 Run `status.sh` on this repository and record the output here; expected: M002 gate line. Actual (worktree at 6b6be26, clean tree): `f002-status-milestone-gates  9/10 tasks → tasks ticked since the last test change, add or run tests`. No M002 gate line, because F002 and F003 are active with `Milestone: m002`; the gate line appears once both are archived. No unpushed line, because local `main` has no commits beyond its upstream in this clone.
