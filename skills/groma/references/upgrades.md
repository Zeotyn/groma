# Upgrade notes

Update mode reads this table to explain what a newer groma adds to a project that was initialized with an older version (`initialized_with` in `.groma/config.yaml`). Add a row with every release that changes mandatory docs, config schema or conventions.

| Version | Change | Action in update mode |
|---|---|---|
| Unreleased | `npx groma` CLI (init, update, status, doctor); config key `agents_via_plugin`; `.groma/generated.json` with hashes of copied skill files | Mention `npx groma update` to refresh copies; nothing to migrate |
| 0.1.0 | Initial release: mandatory docs README, vision, concept, architecture, data-model, glossary, risks, adr/; config schema 1; change convention m/c/f/s/r/d | Create missing mandatory docs; nothing to migrate |

## Config schema migrations

| From | To | Steps |
|---|---|---|
| - | 1 | Initial schema |
