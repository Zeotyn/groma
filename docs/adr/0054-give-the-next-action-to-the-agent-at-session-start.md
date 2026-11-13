---
status: proposed
date: 2026-11-13
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/scripts/next-session.sh, hooks/hooks.json, tests/scripts/next-session.bats, tests/manual/claude-plugin-next-hooks-2026-11-13.md]
origin: c014-plugin-next-hooks#D3
---

# Give the next action to the agent at session start, once per session

## Context and Problem Statement

ADR 0042 keeps the next action on display-only channels: the user sees it, the agent does not. After a break, a `/clear` or a compaction the agent then starts without knowing where the work stands, and the user has to repeat it. The spike (ADR 0050) showed that SessionStart output reaches the model request.

## Decision Drivers

* The agent knows the next step when a session starts
* No tokens on every turn, no uninvited turns (ADR 0042)

## Considered Options

* SessionStart prints the long line as `hookSpecificOutput.additionalContext`; Stop stays display-only
* SessionStart display-only
* Inject the line on every prompt

## Decision Outcome

Chosen option: "SessionStart prints the long line as `additionalContext`", because one line per session start costs almost nothing and starts no turn. This amends the scope of ADR 0042, whose title says "never steer the agent": the rule now holds for every channel except this one. The Stop hook, the status line and every other channel stay display-only; SessionStart alone gives the agent one line of context per session start, labelled as orientation, and still starts no turn.

Details:
- `next-session.sh` prints one JSON line `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"…"}}`; the text is the line of `next.sh --long` behind a short label that says it is for orientation. No next action: no output.
- The hook fires for `startup`, `resume`, `clear` and `compact`, so the line is in the context again after it was dropped. It keeps no state: once per event is once per session start.
- The JSON form is used instead of plain stdout, because Claude Code labels it "additional context" instead of "hook success".

### Consequences

* Good, because the agent can answer "where were we" without running a script.
* Bad, because an agent may act on the line unasked; the label tells it to wait for the user.
* Neutral, because ADR 0042 is no longer the whole rule: read it together with this ADR.
* Bad, because `clear` and `compact` are known from the docs only; they exist only in interactive sessions.

### Confirmation

`tests/scripts/next-session.bats` asserts the JSON shape, the escaping and the silence when off. `tests/manual/claude-plugin-next-hooks-2026-11-13.md` records a session with the plugin whose model request holds the line.

## Pros and Cons of the Options

### SessionStart display-only

* Bad, because the agent would still not know where the work stands.

### Inject on every prompt

* Bad, because it costs tokens on every turn (ADR 0042).

## More Information

From design decision D3 of c014-plugin-next-hooks. Related: ADR 0042, ADR 0050, ADR 0052.
