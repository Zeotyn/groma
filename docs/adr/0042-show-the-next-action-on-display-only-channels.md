---
status: accepted
date: 2026-11-12
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/scripts/next-stop.sh, skills/groma/agents.yaml, tests/scripts/next.bats, tests/manual/copilot-agentstop-2026-11-12.md]
origin: c007-next-action#D1
---

# Show the next action on display-only channels, never steer the agent

## Context and Problem Statement

The next action should reach the user after each answer without anyone asking for it. Agent CLIs offer stop hooks with several output channels: some only display text to the user, others block the stop, retry the turn or send a follow-up message to the agent.

## Decision Drivers

* No extra agent turns, no token cost, no loops
* The user decides what happens next, not the hook

## Considered Options

* Display-only channels (`systemMessage` in Claude Code; stderr with exit 2 in Copilot CLI, verified headless only)
* Steer the agent through a blocking or follow-up channel so it acts on the next step itself
* Inject the next action as context on every prompt (UserPromptSubmit)

## Decision Outcome

Chosen option: "Display-only channels", because they cost nothing and cannot change what the agent does. An agent whose CLI has no display-only channel gets no hook (`hook.status: none` in `agents.yaml`); the AGENTS.md "Session end" line covers it.

### Consequences

* Good, because a hook can never start a turn or loop.
* Bad, because Cursor and other agents without such a channel only get the AGENTS.md line.

### Confirmation

`tests/scripts/next.bats` asserts that `next-stop.sh` prints a JSON object whose only key is `systemMessage`, never `decision`. `tests/manual/claude-stop-hook-2026-11-12.md` shows one notice and no extra turn in Claude Code. The Copilot channel was checked in headless mode only (`tests/manual/copilot-agentstop-2026-11-12.md`), so its adapter stays `experimental` until the interactive TUI is checked.

## Pros and Cons of the Options

### Steer the agent

* Good, because the agent could act on the next step at once.
* Bad, because it creates uninvited turns, costs tokens and can loop.

### Inject context on every prompt

* Bad, because it costs tokens on every turn and the model may drop it.

## More Information

From design decision D1 of c007-next-action.
