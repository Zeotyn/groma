## Why

The evals workflow ran every night at 03:17 UTC. Each run starts headless Claude sessions on all fixtures, which costs up to about 24 USD, whether or not anything changed. Since 2026-11-10 the scheduled runs also failed at once because the repository has no `ANTHROPIC_API_KEY`, so they produced red runs and no information. The maintainer does not want scheduled eval runs at all.

## What Changes

- `.github/workflows/evals.yml`: remove the `schedule` trigger. Evals run only on demand (manual workflow run) and on pull requests labeled `eval`.
- The release gate keeps running the evals before a tag (`scripts/test.sh evals`), as M003 did.
- ADR 0008 gets an amendment note; its decision (four test levels) stands.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `suite-testing`: the agent evals requirement no longer asks for nightly runs.

## Docs impact

- `docs/adr/0008-four-level-test-strategy.md`: amendment note. No other doc mentions the schedule.

## Impact

`.github/workflows/evals.yml` only. No cost from scheduled runs; no red nightly runs.
