Milestone: m003

## Why

The M003 eval run on 2026-11-12 failed one assertion on the `empty` fixture: "openspec context has the code-style line". The eval environment has no network, so groma correctly left the OpenSpec init pending in `.groma/install.sh` and put the code-style context line into the findings report as a snippet, as the methodology-setup spec requires when the config does not exist yet. The assertion only looked in `openspec/config.yaml`, which never exists on that path. The skill was right; the assertion was too strict.

## What Changes

- `tests/evals/assert.sh` (`empty`): when `openspec/config.yaml` exists, it must hold the code-style line as before; when it does not, the assertion requires `steps.methodology: pending`, the OpenSpec init in `.groma/install.sh`, and the code-style line in the findings snippet.

## Capabilities

### New Capabilities
<!-- none: test-only fix (skip_specs: true) -->

### Modified Capabilities
<!-- none -->

## Docs impact

none, because only an eval assertion changes; no behavior, doc or decision changes.

## Impact

`tests/evals/assert.sh` only. Verified by re-asserting the recorded 2026-11-12 run of `empty` (no new tokens) and a negative case with the line removed from the findings.
