Milestone: m004

## Why

Some groma text sits in the agent's context on every turn: the eight skill descriptions once the plugin is installed, and the generated `AGENTS.md` (up to 150 lines) in every project. Every word there costs on every turn, in every session, in every project. That is where trimming saves the most, and C010 makes it measurable.

## What Changes

- Trim the eight SKILL.md `description` fields to what triggers the skill: front-loaded leading word, one trigger per branch, no restated identity.
- Trim the AGENTS.md template: pointers instead of restated content, no lines the agent follows by default.
- A structure check caps description length and the template's line count.
- Measure before and after with the C010 report on the same fixtures; record the difference.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `agent-instructions`: the generated AGENTS.md stays within a smaller line budget.

## Docs impact

`docs/concept.md` if the budget becomes a stated principle; ADR if the budget numbers need a rationale.

## Impact

All eight `SKILL.md` frontmatters, `skills/groma-agents/templates/AGENTS.md`, `tests/structure/check.py`. Evals must stay green: trimmed descriptions must still trigger.
