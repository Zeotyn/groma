# Upgrade notes

Update mode reads this table to explain what a newer groma adds to a project that was initialized with an older version (`initialized_with` in `.groma/config.yaml`). Add a row with every release that changes mandatory docs, config schema or conventions.

| Version | Change | Action in update mode |
|---|---|---|
| Unreleased | `npx groma` CLI (init, update, status, doctor); config key `agents_via_plugin`; `.groma/generated.json` with hashes of copied skill files | Mention `npx groma update` to refresh copies; nothing to migrate |
| Unreleased | Living docs: `docs-impact.sh` (groma-lay-out), config keys `docs.gate` and `docs.adr_from`, ADR frontmatter `origin`, docs reminders in `status.sh`, OpenSpec rules for docs impact, Docs task group and decision alternatives | Offer to add `docs.gate: review` and `docs.adr_from: design-alternatives` to the config (missing keys mean these defaults); existing `openspec/config.yaml`: print the three rules from `methodologies.yaml` as a snippet; mention the living-docs line for AGENTS.md as a snippet |
| 0.1.0 | Initial release: mandatory docs README, vision, concept, architecture, data-model, glossary, risks, adr/; config schema 1; change convention m/c/f/s/r/d | Create missing mandatory docs; nothing to migrate |

## Config schema migrations

| From | To | Steps |
|---|---|---|
| - | 1 | Initial schema |
