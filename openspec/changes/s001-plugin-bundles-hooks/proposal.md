Milestone: m004

## Why

Two M004 changes depend on Claude Code plugin behavior nobody has verified for groma: offering several plugins with different skill subsets from one repository (C009), and shipping hooks inside the plugin instead of writing settings files (C014). Building either on a guess risks a redesign. This spike answers the questions with real runs before the code is written.

## What Changes

Answer four questions with a throwaway marketplace and recorded runs against the current Claude Code and Copilot CLI:

1. **Bundles:** can one repository's `.claude-plugin/marketplace.json` list several plugins (`groma` with all skills, `groma-docs` with detect, survey and lay-out, `groma-loop`) whose skill sets differ, without duplicating the skill folders? If not, what is the smallest layout that works (per-plugin folders with symlinks, generated copies, a `skills` path field)?
2. **Plugin hooks:** does a `hooks/hooks.json` inside the plugin register `SessionStart` and `Stop` hooks without any edit to `settings.json`, as the i-have-adhd and ponytail plugins do? Which environment variables (`CLAUDE_PLUGIN_ROOT`, `CLAUDE_PROJECT_DIR`) does a hook command get?
3. **SessionStart into context:** does plain stdout of a `SessionStart` hook reach the agent's context for `startup`, `resume`, `clear` and `compact`? Is a JSON form (`hookSpecificOutput.additionalContext`) needed or better?
4. **Copilot:** can a Copilot CLI plugin ship hooks the same way?
5. **Plugin off per project:** how does a user switch an installed plugin off for one project only (for example `enabledPlugins` in the project's `.claude/settings.json`, or the plugin manager)? C016 prints this hint when the project holds its own copy of the groma skills.

The spike ends in an ADR that records the answers and the chosen layout, or in a follow-up change when an answer changes C009 or C014. No production code.

## Capabilities

### New Capabilities
<!-- none: spike (skip_specs: true) -->

### Modified Capabilities
<!-- none -->

## Docs impact

An ADR with the results; `tests/manual/` protocols for each run. No other docs change.

## Impact

Throwaway repositories only. Results decide the build of C009 and C014.
