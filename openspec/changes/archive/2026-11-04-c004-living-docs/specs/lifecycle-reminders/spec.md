## ADDED Requirements

### Requirement: Docs reminders
When `docs.gate` is not `off`, the status script SHALL remind for an active change whose tasks are all done and whose docs impact report is not empty ("update docs/<file> or add a Docs: task line"), and for an ADR with `status: proposed` whose `origin` change is archived ("accept or reject ADR NNNN"). The docs reminder SHALL take priority over the verify-and-archive reminder.

#### Scenario: Done but docs open
- **WHEN** all tasks of `c007-cache` are ticked and the report lists `docs/architecture.md`
- **THEN** the status line for `c007-cache` reads `… → update docs/architecture.md or add a Docs: task line`

#### Scenario: Pending ADR after archive
- **WHEN** `c007-cache` is archived and `docs/adr/0011-use-redis.md` still has `status: proposed`
- **THEN** the status output contains `ADR 0011 still proposed (c007-cache archived) → accept or reject`
