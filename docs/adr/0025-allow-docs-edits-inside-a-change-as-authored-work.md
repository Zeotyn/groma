---
status: proposed
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-loop/SKILL.md, skills/groma-lay-out/SKILL.md]
origin: c004-living-docs#D4
---

# Treat docs edits inside a change as authored work

## Context and Problem Statement

ADR 0006 forbids groma's setup skills from editing existing files in a target project. Keeping `docs/architecture.md` current inside a user's change means editing an existing file.

## Considered Options

* Docs edits inside a change count as authored work, like code edits in that change; archive sync touches only docs the change created or modified
* Write doc updates as snippets into `docs/_groma/`
* Extend ADR 0006 with exceptions

## Decision Outcome

Chosen option: "Docs edits are authored work", because they are the same kind of work as the code edits the user asked for in that change. This narrows the scope of ADR 0006 to setup writes. It does not supersede it. Snippets would leave docs permanently out of date. Exceptions in ADR 0006 would blur a simple rule, so this ADR states the scope instead.

### Consequences

* Good, because docs can become current without weakening the setup rule.
* Bad, because the boundary between setup writes and authored work needs care in each skill.

### Confirmation

The checksum invariant in `tests/invariant/checksum.sh` still covers setup runs. Review checks that archive sync edits only docs the change already touched.

## More Information

From design decision D4 of c004-living-docs. Narrows the scope of ADR 0006. ADR 0006 stays accepted.
