---
status: accepted
date: 2026-11-13
decision-makers: Eugen Waldschmidt
evidence: [skills/groma/SKILL.md, skills/groma/templates/config.yaml, skills/groma/scripts/validate-config.sh, cli/init.js]
origin: c016-agent-only-init#D2
---

# Copy the groma skills into the project by default on the agent path

## Context and Problem Statement

With `materialize.sh` (ADR 0057) `/groma` can copy the groma skills into the project. Should it do so unasked, on request, or by default? Without the copy the skills live only in the user's plugin or home folder: a teammate who clones the repository gets neither `/groma` nor `groma-loop`.

## Decision Drivers

* Everything groma sets up lives in the project and is versioned with the code
* Some plugin users keep their repository free of tool folders
* One question at most, with a recommended answer

## Considered Options

* Ask once, recommended yes, and copy on yes
* Copy only on request
* Always copy without asking

## Decision Outcome

Chosen option: "ask once, recommended yes", because team repositories depend on the copy and the user can still decline.

Details:
- In step 7 (agents) `/groma` asks "Put the groma skills into the project so the team gets them with the repository?" in the user's language, then runs `materialize.sh` for the selected agents.
- The answer is recorded in the new config key `steps.skills_copy`: `done` after a copy, `skipped` after a no. `groma init` writes `done` when it copied for at least one agent. The key is not one of the eight steps; it is the copy state inside the agents step, so `/groma` asks once and does not ask again after `groma init`.
- Update mode runs `materialize.sh --update` when the key is `done` (or when `.groma/generated.json` exists in a project from an older version) and reports edited copies. It no longer sends the user to `npx groma-cli update` for the copies.
- The CLI stays as the faster terminal path with the same result.

### Consequences

* Good, because a clone of the repository carries the groma skills for every selected agent.
* Good, because a declined copy is remembered.
* Bad, because the repository gains about a hundred files per agent.

### Confirmation

`tests/scripts/validate-config.bats` accepts `steps.skills_copy`; `cli/test/init.test.js` checks the key after `groma init`. The question itself is skill text and is covered by the evals.

## Pros and Cons of the Options

### Copy only on request

* Bad, because teams depend on the copy and would learn about it too late. Rejected by the user on 2026-11-12.

### Always copy without asking

* Bad, because some plugin users keep their repository free of tool folders.

## More Information

Decision D2 of `openspec/changes/c016-agent-only-init/design.md`. Related: ADR 0020, ADR 0057.
