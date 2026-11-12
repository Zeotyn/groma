Milestone: m004

## Why

The Claude marketplace offers one plugin with all eight skills. Someone who wants only the docs part (detect, survey, lay-out) or only the review loop has to take everything, including the methodology and catalog installers. Bundles let people install the part they trust, without the CLI.

## What Changes

- `.claude-plugin/marketplace.json` lists bundles in the layout S001 confirms:
  - `groma`: all skills (unchanged);
  - `groma-docs`: groma-detect, groma-survey, groma-lay-out;
  - `groma-loop`: groma-loop (plus whatever its standalone test needs after R001).
- Each bundle has its own manifest with the shared version; the version check covers them.
- README "Install" gains a bundle table; a test installs each bundle into a temporary plugin dir and lists its skills.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `distribution`: the Claude Code marketplace exposes bundles besides the full plugin.

## Docs impact

README "Install"; `docs/architecture.md` distribution part; ADR if S001 leaves a layout choice open.

## Impact

`.claude-plugin/`, possibly per-bundle folders (per S001), `tests/structure/check.py`, `scripts/release-check.sh` (versions of every bundle manifest).
