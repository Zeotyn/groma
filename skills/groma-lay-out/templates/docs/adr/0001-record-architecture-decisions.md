---
status: accepted
date: {{today}}
decision-makers: {{owner}}
---

# Record architecture decisions

## Context and Problem Statement

Decisions about structure, technology and conventions get lost in chats and commit messages. New team members and coding agents cannot tell why the system looks the way it does.

## Considered Options

* Architecture decision records in the repository (MADR 4.0)
* Wiki pages outside the repository
* No written record

## Decision Outcome

Chosen option: "Architecture decision records in the repository (MADR 4.0)", because they are versioned with the code, reviewable in pull requests and readable by agents.

### Consequences

* Good, because every significant decision has a place, a status and a history.
* Bad, because writing an ADR takes a few minutes per decision.

### Confirmation

Pull requests that change architecture link an ADR. groma surveys report projects without ADRs.
