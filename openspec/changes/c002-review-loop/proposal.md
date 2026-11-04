Milestone: m001

## Why

A single agent that proposes and implements its own changes reviews its own blind spots. Users also forget the end of the lifecycle: changes with all tasks done stay unarchived, tasks get ticked without tests. groma already sets up the methodology; it should also run the work through a review loop with a second model and remind users what is left.

## What Changes

- New skill `groma-loop`: orchestrator mode for the change lifecycle. Propose and apply each run in a review loop: an author model writes, a different reviewer model reviews, the author answers every finding, until the stop criterion holds or the round limit is reached.
- Reviewer selection `auto` (default): groma picks the most independent reviewer available (another vendor's CLI, else another model of the same agent, else a marked self-review). Users can pin a reviewer per phase.
- Two modes, chosen by the user, default **autonomous**: no approval stops; groma escalates to the human only when the loop is stuck. `gated` mode adds approval after propose and before archive.
- Deterministic gate first: during apply, tests must be green before a review round starts.
- Review records stored in the change folder and archived with it.
- Lifecycle reminders: a status script lists changes ready to verify or archive, stale changes and tasks ticked without test changes; AGENTS.md tells agents to run it at session start; optional Claude Code hook runs it automatically.
- New `review` and `reminders` sections in `.groma/config.yaml`, with defaults written by `/groma`.

## Capabilities

### New Capabilities
- `review-loop`: orchestrated propose/apply/verify/archive with author/reviewer roles, reviewer resolution, stop criteria, finding responses, escalation, modes, config.
- `lifecycle-reminders`: status report of open lifecycle work, how agents and hooks surface it, config.

### Modified Capabilities
<!-- none yet: the capabilities of C001 are not archived; C002 adds its config keys and template changes as its own requirements -->

## Impact

- New skill folder `skills/groma-loop/` with scripts and references; `groma-methodology` gains `scripts/status.sh`.
- Config template and validator gain `review` and `reminders`; AGENTS.md template gains a session-start line.
- Optional dependency on other agent CLIs as reviewers (`codex`, `gemini`, `copilot`, `claude`), each with its own login.
- Token cost grows with rounds; bounded by `max_rounds` and diff-only reviews.
