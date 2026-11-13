---
status: accepted
date: 2026-11-13
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-agents/templates/statusline-pill.sh, skills/groma-agents/templates/statusline-snippet.sh, skills/groma-agents/SKILL.md, tests/scripts/next-session.bats]
origin: c014-plugin-next-hooks#D5
---

# Ship a pill line for status lines that already render pills

## Context and Problem Statement

C007 ships a standalone status-line script and a plain `▶ push 3` line. Many users already have a status line built from colored pills, one per tool. They had to adapt the plain line by hand.

## Decision Drivers

* A line that can be pasted as it is
* groma never edits a status line (ADR 0044)

## Considered Options

* A one-line pill (`▶ <next.sh --short>` on a colored background) as a snippet, next to the standalone script
* Only the standalone script and the plain line

## Decision Outcome

Chosen option: "a one-line pill as a snippet", because it fits status lines that already render pills and stays inside ADR 0044.

Details:
- `templates/statusline-pill.sh` holds the line. It prints nothing when there is no next action.
- The line finds `next.sh` through a pattern, so that a plugin install survives a plugin update: the version folder of the plugin cache is a `*`, and the highest version wins (`sort -V`, so 0.10.0 beats 0.4.0).
- A child `sh -c` expands the pattern, so the line behaves the same in a zsh or bash status line; in zsh a pattern without a match would otherwise abort the user's whole script.
- The pill shows the next action whenever the user pasted it; the on/off rule of ADR 0053 is for the hooks.

### Consequences

* Good, because users with their own status line paste one line.
* Bad, because the pill's colors are groma's guess; the user adapts them to the neighbours.

### Confirmation

`tests/scripts/next-session.bats` runs the pill line of the template against a project and checks the output with and without a next action, with two cached versions, and in zsh with a pattern that matches nothing. groma-agents step 5 says never to edit a status line.

## Pros and Cons of the Options

### Only the standalone script

* Bad, because users with their own status line would have to adapt it.

## More Information

From design decision D5 of c014-plugin-next-hooks. Related: ADR 0044.
