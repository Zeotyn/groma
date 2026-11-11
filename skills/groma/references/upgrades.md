# Upgrade notes

Update mode reads this table to explain what a newer groma adds to a project that was initialized with an older version (`initialized_with` in `.groma/config.yaml`). Add a row with every release that changes mandatory docs, config schema or conventions.

| Version | Change | Action in update mode |
|---|---|---|
| 0.3.0 | Git workflow: config section `git` (`integrate`, `branch_per_change`, `commits`, `push`), `git-practice.sh` (groma-detect), strategies table `git-strategies.md` (groma-agents), "Git workflow" section in the AGENTS.md template, branch, commit, integrate and push steps in groma-loop, merge-base base in `docs-impact.sh` | Ask the two git questions of the interview (brownfield: with the `git-practice.sh` recommendation and its evidence) and offer to add the `git` section to the config; missing keys mean the defaults. Existing `AGENTS.md` without a "Git workflow" section: put the section of `../groma-agents/templates/AGENTS.md` (placeholders resolved) into the findings report as a snippet; an existing `AGENTS.md` is never edited (ADR 0006), whoever wrote it |
| 0.3.0 | Code style: mandatory doc `docs/code-style.md`, `style-drift.sh` (groma-survey), tools table `code-style-tools.md` and config templates (groma-lay-out), "Code style" section in the AGENTS.md template, code-style line in the methodology context, style checks in groma-loop's tests gate and review prompt | Fill the code-style slot like any missing mandatory doc (brownfield: run the survey's Code style step first); report it as new in the findings. Do not create tool configs or ADRs unless the user asks for the style setup; existing `AGENTS.md`: put the "Code style" section of `../groma-agents/templates/AGENTS.md` (with `{{style_checks}}` resolved) into the findings report as a snippet; existing `openspec/config.yaml`: print the context line from `methodologies.yaml` as a snippet |
| 0.2.0 | `npx groma-cli` CLI (init, update, status, doctor); config key `agents_via_plugin`; `.groma/generated.json` with hashes of copied skill files | Mention `npx groma-cli update` to refresh copies; nothing to migrate |
| 0.2.0 | Living docs: `docs-impact.sh` (groma-lay-out), config keys `docs.gate` and `docs.adr_from`, ADR frontmatter `origin`, docs reminders in `status.sh`, OpenSpec rules for docs impact, Docs task group and decision alternatives | Offer to add `docs.gate: review` and `docs.adr_from: design-alternatives` to the config (missing keys mean these defaults); existing `openspec/config.yaml`: print the three rules from `methodologies.yaml` as a snippet; existing `AGENTS.md`: put the "Living docs" bullet of `../groma-agents/templates/AGENTS.md` (with `{{docs_impact_script}}` resolved) into the findings report as a snippet |
| 0.1.0 | Initial release: mandatory docs README, vision, concept, architecture, data-model, glossary, risks, adr/; config schema 1; change convention m/c/f/s/r/d | Create missing mandatory docs; nothing to migrate |

## Config schema migrations

| From | To | Steps |
|---|---|---|
| - | 1 | Initial schema |
