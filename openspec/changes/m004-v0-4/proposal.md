## Why

groma 0.3 is usable only in full: the skills reach into each other's folders, so a single skill installed with `npx skills add --skill` breaks, and the Claude marketplace offers one all-or-nothing plugin. People who do not want the CLI, or already have their own setup, cannot pick the parts they trust. groma also claims to work token-efficiently without a single measured number, and the next action still needs hand-written settings to appear. v0.4 makes the skills usable without the CLI, makes token cost measurable, and ships the next-action hooks inside the plugin.

## What Changes

Milestone only; behavior is specified in the child changes.

**Goal:** Every groma skill installed alone with `npx skills add Zeotyn/groma --skill <name>` passes its standalone test; the marketplace offers the bundles the spike confirms (at least `groma` and `groma-docs`); the eval run writes a token and cost report per fixture with a recorded baseline, and the always-loaded diet and the survey subagent are measured against it; the effect measurement compares one task with and without groma docs; with the plugin installed and the next action switched on, a new Claude Code session starts with the next action in the agent context and no settings file was written; groma talks to the user in the user's language. `v0.4.0` tagged and published through the release workflow, all test levels green.

**Scope:**
- In: everything specified in `s001-plugin-bundles-hooks`, `r001-vendor-shared-files`, `c009-marketplace-bundles`, `c010-token-report`, `c011-always-loaded-diet`, `c012-survey-subagent`, `c013-effect-measurement`, `c014-plugin-next-hooks` and `c015-user-language`.
- Out: the language of generated project docs; a hosted skill registry; network signals for the next action (CI, PR state); Copilot plugin hooks unless the spike confirms them.

**Child changes:**

| Id | Change | Order |
|---|---|---|
| S001 | `s001-plugin-bundles-hooks` | first: decides how C009 and C014 are built |
| R001 | `r001-vendor-shared-files` | before C009 |
| C009 | `c009-marketplace-bundles` | after S001 and R001 |
| C010 | `c010-token-report` | before C011, C012, C013 |
| C011 | `c011-always-loaded-diet` | after C010 |
| C012 | `c012-survey-subagent` | after C010 |
| C013 | `c013-effect-measurement` | last of the token changes |
| C014 | `c014-plugin-next-hooks` | after S001 |
| C015 | `c015-user-language` | independent |

## Capabilities

### New Capabilities
<!-- none: milestone without spec deltas (skip_specs: true) -->

### Modified Capabilities
<!-- none -->

## Docs impact

none, because the milestone only groups child changes; each child names its own docs.

## Impact

Plans the v0.4 release. No code changes in this change.
