Milestone: m004

## Why

The C010 baseline eval run on 2026-11-13 reported 6 of 8 fixtures passing. Both failures were assertions stricter than the behaviour the specs allow, not groma defects:

- `empty`: with the OpenSpec init pending, the agent put the code-style context line into `.groma/install.sh` next to the init command (where the methodology-setup spec's pending path leads) instead of the findings report; the assertion looked only in the findings.
- `cli-node-prisma`: the summary recommended `npx groma-cli update` twice, but as its first line; the assertion read only the last 20 lines of the log, which since C010 holds stderr plus the agent's final text.

## What Changes

- `tests/evals/assert.sh` (`empty`): the pending code-style line counts in the findings report or in `.groma/install.sh`.
- `tests/evals/assert.sh` (`cli-node-prisma`): the update hint counts anywhere in the log, not only in its last 20 lines.

## Capabilities

### New Capabilities
<!-- none: test-only fix (skip_specs: true) -->

### Modified Capabilities
<!-- none -->

## Docs impact

none, because only eval assertions change; no behaviour, doc or decision changes.

## Impact

`tests/evals/assert.sh` only. Verified by re-asserting the recorded 2026-11-13 run of both fixtures (no new tokens) and by negative cases with the content removed.
