Milestone: m004

## Why

CI went red on 2026-11-13 after the push of C014: the pinned shellcheck 0.10.0 in `.github/workflows/test.yml` flags the `unlock` function in `next-stop.sh` as unreachable (SC2317), because it is only called by the `EXIT` trap. The local shellcheck 0.11.0 reports the same case as SC2329, which the script already disabled, so the local test run stayed green.

## What Changes

- `skills/groma-methodology/scripts/next-stop.sh`: the directive above `unlock` disables SC2317 and SC2329, so both shellcheck versions accept it.

## Capabilities

### New Capabilities
<!-- none: lint fix (skip_specs: true) -->

### Modified Capabilities
<!-- none -->

## Docs impact

none, because only a lint directive changes; no behaviour, doc or decision changes.

## Impact

`next-stop.sh` only. Verified with shellcheck 0.10.0 (as in CI) and 0.11.0 over every script `scripts/test.sh` checks.
