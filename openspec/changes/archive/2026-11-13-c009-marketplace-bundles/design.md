## Context

ADR 0050 (spike S001) fixed the layout: bundles are entries of `.claude-plugin/marketplace.json` with `source: "./"` and a `skills` list; no per-bundle folders. ADR 0051 made every skill folder self-contained, so a bundle needs no extra files. This change applies that layout and makes the checks cover every entry.

## Decisions

- D1: The bundle contents live in one constant, `BUNDLES` in `tests/structure/check.py`; the structure check `bundles` fails on an unknown, missing or duplicated entry, a source other than `./`, a missing version, or a skill list that differs from the constant. The spec names the bundles, so the check pins them instead of accepting any list.
- D2: `groma-loop` contains only `groma-loop`. Its two hand-offs (groma-lay-out for ADR candidates, groma-methodology's roadmap) already print the skill to add and skip the step when the sibling is missing (`scripts/handoffs.txt`, `tests/scripts/standalone.bats`), so nothing more is needed for it to work alone.
- D3: `scripts/release-check.sh` reads the marketplace with a small JSON scanner in `awk`: only the objects of the top-level `plugins` array count, and only their own `name` and `version` keys (not nested objects, not `metadata`). Each entry's version is compared with the tag; an entry without one is named in the failure (`#<position>` when it has no name).

No ADR: the layout choice was made in ADR 0050 and this change leaves no open alternative.

## Implementation notes

- Spec scenario "Docs bundle only": installing `groma-docs` and listing its skills is automated in `tests/scripts/bundles.bats` (isolated `CLAUDE_CONFIG_DIR` in the bats temp dir, no model call). That a survey run from the bundle produces its findings report needs a model: it is check 2 of the manual protocol `tests/manual/claude-bundles.md`, not run in this change (no evidence yet). The survey skill's standalone and script tests cover it running from its folder alone.
- `tests/scripts/bundles.bats` needs no login (verified with an empty `HOME`, a fresh config dir and no API key). `.github/workflows/test.yml` now installs Claude Code (unpinned, like `evals.yml`, so a release that changes bundle loading fails CI); in CI a missing `claude` fails the test, locally it skips.
- Review fixes: release-check parses per entry (D3) instead of counting `source` and `version` keys, which passed when `metadata` carried a version; bundle versions must be SemVer; marketplace entry names must be the plugin name or a `BUNDLES` key.
- The CLI's plugin detection (`cli/init.js` `claudePluginInstalled`) matches only `groma@`, so a project with only `groma-docs@groma` or `groma-loop@groma` still gets the skill copies from `npx groma-cli init`. That is intended: a bundle lacks the other skills. Unchanged.
- Copilot CLI reads the same marketplace file; whether it honours the `skills` list was not tested, so the README recommends `groma@groma` there.
- CHANGELOG `[Unreleased]`: by the integrator, not in this branch.
