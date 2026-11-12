---
status: accepted
date: 2026-11-12
decision-makers: Eugen Waldschmidt
evidence: [skills/groma/agents.yaml, tests/structure/check.py, tests/manual/copilot-agentstop-2026-11-12.md]
origin: c007-next-action#D6
---

# Describe hook adapters per agent as data

## Context and Problem Statement

Each agent CLI has a different hook for "the agent finished an answer", with different output channels. Some of these channels only show text to the user, others feed text back to the model. groma must use only display-only channels (ADR 0042), and which channel is display-only had to be found out per agent.

## Decision Drivers

* Agent knowledge belongs in data, not in skill logic (ADR 0004)
* A channel is trusted only after it was tested
* Agents without a usable channel still get the next action

## Considered Options

* A `hook` entry per agent in `agents.yaml` with `status` (stable, experimental, none), `event`, `config` and `format`; the Copilot entry set by a spike
* Hard-coded per-agent logic in groma-agents
* Claude only

## Decision Outcome

Chosen option: "A `hook` entry per agent in `agents.yaml`", because adding or promoting an agent is a table edit, and the status tells groma-agents whether to offer the hook.

Current entries: claude `stable` (`Stop`, `systemMessage`); copilot `experimental` (`agentStop`, `stderr-exit2`, from the spike: stdout and `systemMessage` are ignored, stderr with exit 2 is shown without a new turn in headless mode, the interactive TUI is unverified); gemini and codex `experimental`; cursor `none`, because its `stop` hook sends a follow-up message to the agent.

### Consequences

* Good, because a structure check enforces a valid `hook` entry for every agent.
* Good, because agents with `none` still get the AGENTS.md fallback line and `groma next`.
* Bad, because `experimental` entries are documented but untested, and need a manual check before they become `stable`.

### Confirmation

`tests/structure/check.py` fails when an agent lacks a `hook` entry or has an unknown status. `tests/manual/copilot-agentstop-2026-11-12.md` records the spike.

## Pros and Cons of the Options

### Hard-coded per-agent logic

* Bad, because it puts agent knowledge into skill logic, against ADR 0004.

### Claude only

* Bad, because the data-driven fallback costs nothing to keep open for the other agents.

## More Information

From design decision D6 of c007-next-action. Related: ADR 0004, ADR 0042.
