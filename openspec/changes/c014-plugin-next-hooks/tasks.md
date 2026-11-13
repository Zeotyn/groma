## 1. Tests first

- [x] 1.1 bats: SessionStart wrapper prints the long line when on, nothing without `.groma/`, nothing when `next.hook: off`; on/off table (project on/off/unset × flag file present/absent) with a temp HOME; no-`.groma/` case under 50 ms
- [x] 1.2 validate-config bats: `hook: auto` accepted, unset accepted, other values rejected with line number

## 2. Hooks and config

- [x] 2.1 `hooks/hooks.json` in the plugin per S001; SessionStart wrapper; Stop reuses `next-stop.sh` with the on/off rule
- [x] 2.2 Config template leaves `next.hook` unset; validator accepts `auto`
- [x] 2.3 groma-agents: plugin case prints the flag command with its reason and the pill line; settings path unchanged without the plugin
- [x] 2.4 Pill snippet template
- [x] 2.5 Manual protocol: new session with the plugin shows the next action in the agent context, `tests/manual/claude-plugin-next-hooks-<date>.md`; `scripts/test.sh` green

## 3. Docs

- [x] 3.1 README "Next action"; `docs/architecture.md`; `docs/data-model.md`; ADRs for D1 to D4 (0052 to 0055, plus 0056 for D5); `docs/concept.md`; CHANGELOG `[Unreleased]` (left to the integrator, see design.md "Implementation notes")
- [x] Docs: `docs/code-style.md` unchanged, because the new scripts, tests and the `hooks` structure check follow the existing conventions and add none
- [x] Docs: `docs/vision.md` unchanged, because the README change is confined to the "Next action" section and does not move the vision
