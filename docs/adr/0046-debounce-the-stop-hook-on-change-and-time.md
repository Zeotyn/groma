---
status: proposed
date: 2026-11-12
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/scripts/next-stop.sh, tests/scripts/next.bats, tests/manual/claude-stop-hook-2026-11-12.md]
origin: c007-next-action#D5
---

# Debounce the Stop hook on change and time

## Context and Problem Statement

The opt-in Stop hook shows the next action after the agent answers. The agent answers many times in a session, and most answers do not change the next action. A line that repeats after every answer is quickly ignored.

## Decision Drivers

* The line should appear when it carries news
* A suggestion the user has not acted on should come back eventually
* The state must stay inside `.groma/` (ADR 0006)

## Considered Options

* Show when the line changes or when the last showing is `next.reshow_minutes` old (default 30, 0 shows only on change); state in `.groma/.cache/next-shown`
* Show after every answer
* Show only at session start

## Decision Outcome

Chosen option: "Show on change or after `reshow_minutes`", because it shows new information at once and repeats an ignored suggestion at a slow, configurable pace.

### Consequences

* Good, because the same line is suppressed between answers, and an empty result clears the state.
* Good, because the state file sits in the self-ignoring cache folder next to the next-action cache.
* Bad, because two sessions on the same project share one state file, so one session can suppress a line the other has not shown.

### Confirmation

`tests/scripts/next.bats` covers first show, suppression of the same line, a changed line, a reshow after `reshow_minutes` and clearing on an empty result. The manual run in `tests/manual/claude-stop-hook-2026-11-12.md` shows one notice and none on a second run within 30 minutes.

## Pros and Cons of the Options

### Show after every answer

* Bad, because a line that never changes turns into noise.

### Show only at session start

* Bad, because the SessionStart reminder already covers that moment.

## More Information

From design decision D5 of c007-next-action. Related: ADR 0042.
