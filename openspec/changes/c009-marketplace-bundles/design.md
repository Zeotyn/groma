## Context

ADR 0050 (spike S001) fixed the layout: bundles are entries of `.claude-plugin/marketplace.json` with `source: "./"` and a `skills` list; no per-bundle folders. ADR 0051 made every skill folder self-contained, so a bundle needs no extra files. This change applies that layout and makes the checks cover every entry.

## Decisions

- D1: The bundle contents live in one constant, `BUNDLES` in `tests/structure/check.py`; the structure check `bundles` fails on an unknown, missing or duplicated entry, a source other than `./`, a missing version, or a skill list that differs from the constant. The spec names the bundles, so the check pins them instead of accepting any list.
- D2: `groma-loop` contains only `groma-loop`. Its two hand-offs (groma-lay-out for ADR candidates, groma-methodology's roadmap) already print the skill to add and skip the step when the sibling is missing (`scripts/handoffs.txt`, `tests/scripts/standalone.bats`), so nothing more is needed for it to work alone.
- D3: `scripts/release-check.sh` reads every `"version"` of the marketplace with one `awk` pass, names each by the last `"name"` before it, and reports entries without a version by comparing the count of `"source"` keys with the count of versions.

No ADR: the layout choice was made in ADR 0050 and this change leaves no open alternative.

## Implementation notes

- Spec scenario "Docs bundle only": installing `groma-docs` and listing its skills is automated in `tests/scripts/bundles.bats` (isolated `CLAUDE_CONFIG_DIR` in the bats temp dir, no model call). That a survey run from the bundle produces its findings report needs a model and stays manual; the survey skill's own standalone and script tests cover it running from its folder alone.
- `tests/scripts/bundles.bats` skips when `claude` is not on PATH (CI has no Claude Code), so it runs on developer machines only.
- The CLI's plugin detection (`cli/init.js` `claudePluginInstalled`) matches only `groma@`, so a project with only `groma-docs@groma` or `groma-loop@groma` still gets the skill copies from `npx groma-cli init`. That is intended: a bundle lacks the other skills. Unchanged.
- Copilot CLI reads the same marketplace file; whether it honours the `skills` list was not tested, so the README recommends `groma@groma` there.
- CHANGELOG `[Unreleased]`: by the integrator, not in this branch.
