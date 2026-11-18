Milestone: m004

## Why

The pitch says that project knowledge in the repository makes an agent's work cheaper and better afterwards. C010 to C012 measure what groma itself costs; nothing measures what groma saves later. A controlled comparison on a fixture turns the claim into a number, or shows it does not hold.

## What Changes

- A new eval mode runs the same scripted task (for example "add an endpoint that lists tasks with their time entries") on a brownfield fixture twice: once as is, once after `/groma` laid out docs, AGENTS.md and code style.
- It records tokens, cost, turns and whether the task's acceptance test passes, for each side, several runs per side to see variance.
- The result goes into `tests/evals/reports/effect-<date>.tsv` and a short summary.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `suite-testing`: an effect eval compares one task with and without groma's setup.

## Docs impact

`docs/vision.md` success measures (add the effect measure); README if the result is worth stating.

## Impact

`tests/evals/` (new mode, task prompt, acceptance test). Several eval runs per measurement; cost stated before each run.
