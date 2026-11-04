Milestone: m002

## Why

`status.sh` prints "groma status: nothing open" in this repository while 30 commits are unpushed and M002 waits for its release gate: all child changes are archived, and tasks 2.1–2.4 are open. The script only looks at task progress of active changes, so a milestone between "children done" and "released" gets no reminder, and neither does work that exists only in the working tree or only locally. A reminder tool that says "nothing open" while work is open teaches people to ignore it, and C007's next-action hook will build on this script.

## What Changes

- **Milestone gate reminder:** an active milestone (`m` change) that no active change references with `Milestone: mNNN`, and that still has open tasks, gets `→ gate: <first open task>`.
- **Repository reminders**, printed after the change lines:
  - uncommitted changes: `working tree: <n> files uncommitted → commit or stash`
  - local commits on the main branch not yet on its upstream: `main: <n> commits not pushed → git push`
  - Both read only local state. Nothing is fetched.
- **New toggles** in the `reminders` section: `uncommitted` and `unpushed` (default `true`). The validator accepts them.
- "groma status: nothing open" is printed only when no change, ADR or repository reminder exists.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `lifecycle-reminders`: milestone gate reminder, repository reminders, the "nothing open" condition, the new toggles.
- `project-config`: validator accepts `reminders.uncommitted` and `reminders.unpushed`.

## Impact

- `skills/groma-methodology/scripts/status.sh`, `tests/scripts/status.bats`
- `skills/groma/templates/config.yaml`, `skills/groma/scripts/validate-config.sh`, `tests/scripts/validate-config.bats`
- CLI `groma status` passes through `status.sh` and needs no change.

## Docs impact

- `docs/architecture.md`: the status.sh row mentions milestone and repository reminders.
- `docs/data-model.md`: config entity gains two reminder keys.
- ADRs: none planned. D1 below has alternatives and needs an ADR under the docs gate.
