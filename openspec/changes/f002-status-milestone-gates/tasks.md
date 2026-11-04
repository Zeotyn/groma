## 1. Tests first

- [ ] 1.1 `tests/scripts/status.bats`: milestone at gate (first open task, 60-char cut), milestone with active child (no gate line), gate replaces stale, uncommitted count, unpushed count against a local bare upstream, no upstream → no line, toggles off, "nothing open" only without any line
- [ ] 1.2 `tests/scripts/validate-config.bats`: `reminders.uncommitted` and `reminders.unpushed` accept true/false, reject other values with line number

## 2. Implementation

- [ ] 2.1 `status.sh`: milestone references and gate reminder per D1; header comment updated
- [ ] 2.2 `status.sh`: repository lines per D2, toggles per D3
- [ ] 2.3 `config.yaml` template and `validate-config.sh`; runtime on this repository under 300 ms, else note the measurement here
- [ ] 2.4 `shellcheck -s sh` and `scripts/test.sh` green

## 3. Docs

- [ ] 3.1 `docs/architecture.md` (status.sh row) and `docs/data-model.md` (config keys); proposed ADR for D1 with `origin: f002-status-milestone-gates#D1`
- [ ] 3.2 CHANGELOG `[Unreleased]`: Fixed entry
- [ ] 3.3 Run `status.sh` on this repository and record the output here; expected: M002 gate line
