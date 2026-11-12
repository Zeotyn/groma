## 1. Tests first

- [ ] 1.1 bats: SessionStart wrapper prints the long line when on, nothing without `.groma/`, nothing when `next.hook: off`; on/off table (project on/off/unset × flag file present/absent) with a temp HOME; no-`.groma/` case under 50 ms
- [ ] 1.2 validate-config bats: `hook: auto` accepted, unset accepted, other values rejected with line number

## 2. Hooks and config

- [ ] 2.1 `hooks/hooks.json` in the plugin per S001; SessionStart wrapper; Stop reuses `next-stop.sh` with the on/off rule
- [ ] 2.2 Config template leaves `next.hook` unset; validator accepts `auto`
- [ ] 2.3 groma-agents: plugin case prints the flag command with its reason and the pill line; settings path unchanged without the plugin
- [ ] 2.4 Pill snippet template
- [ ] 2.5 Manual protocol: new session with the plugin shows the next action in the agent context, `tests/manual/claude-plugin-next-hooks-<date>.md`; `scripts/test.sh` green

## 3. Docs

- [ ] 3.1 README "Next action"; `docs/architecture.md`; `docs/data-model.md`; ADRs for D1 to D4; CHANGELOG `[Unreleased]`
