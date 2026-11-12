Milestone: m004

## Why

The Claude marketplace offers one plugin with all eight skills. Someone who wants only the docs part (detect, survey, lay-out) or only the review loop has to take everything, including the methodology and catalog installers. Bundles let people install the part they trust, without the CLI.

## What Changes

- `.claude-plugin/marketplace.json` lists bundles in the layout S001 confirms:
  - `groma`: all skills (unchanged);
  - `groma-docs`: groma-detect, groma-survey, groma-lay-out;
  - `groma-loop`: groma-loop (plus whatever its standalone test needs after R001).
- S001 result (ADR 0050): no per-bundle folders. Each bundle is a marketplace entry with `source: "./"` and a `skills` list of skill subdirectories; only those load. All bundles carry the root manifest's name, so their skills are prefixed `groma:` and the bundles are alternatives. Version: each entry's `version`, covered by the version check.
- README "Install" gains a bundle table; a test installs each bundle into a temporary plugin dir and lists its skills.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `distribution`: the Claude Code marketplace exposes bundles besides the full plugin.

## Docs impact

README "Install"; `docs/architecture.md` distribution part; ADR if S001 leaves a layout choice open.

## Impact

`.claude-plugin/marketplace.json` (no per-bundle folders, ADR 0050), `tests/structure/check.py`, `scripts/release-check.sh` (today it reads only the first `version` in `marketplace.json`; it must check every entry).
