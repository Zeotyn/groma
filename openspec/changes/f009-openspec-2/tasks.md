## 1. Tests first

- [ ] 1.1 `tests/scripts/next.bats`: cases for 1.x markers (`/opsx:apply`), 2.x markers only (`/openspec-apply`, `.agents/skills/openspec-apply-change/`), both present (`/opsx:`), none (no slash command, "verify, then archive"); keep the existing `/opsx:` expectations under a 1.x fixture
- [ ] 1.2 Structure or unit test that every `generations` entry of the `openspec` recipe has `markers` and a `command` with `{step}`

## 2. Recipe and next action

- [ ] 2.1 `skills/groma-methodology/methodologies.yaml`: `generations` (1.x and 2.x markers and command patterns) and `.agents/skills/openspec-*` in `touches`; the CLI (`bin/`, `lib/`) ignores the new key or reads `touches` unchanged (check its tests)
- [ ] 2.2 `next.sh`: pick the command pattern from the first generation whose markers exist, else print no command; stays under 300 ms on a cache miss with 20 changes
- [ ] 2.3 `skills/groma-agents/SKILL.md` methodology hint and `skills/groma-loop/references/methodology-adapters.md` propose row: wording right for both generations
- [ ] 2.4 `scripts/test.sh` green (shellcheck 0.10.0), `openspec validate --all --strict`, `sync-shared.sh --check` `differs=0`, style drift `drift=0`

## 3. Docs

- [ ] 3.1 ADR 0073 (`status: proposed`, `origin: f009-openspec-2#D1`) covering D1 to D3; row in `docs/adr/README.md`
- [ ] 3.2 `docs/architecture.md` (next.sh command form, recipe `generations`); `docs/concept.md` if it names `/opsx:`; `skills/groma/references/upgrades.md` 0.4.0 row; CHANGELOG `[Unreleased]` Fixed entry; docs-impact gate `impact=0 adr=0`
