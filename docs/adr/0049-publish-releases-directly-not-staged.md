---
status: proposed
date: 2026-11-12
decision-makers: Eugen Waldschmidt
evidence: [.github/workflows/release.yml, README.md]
origin: c008-release-workflow#D2
---

# Publish releases directly, not staged

## Context and Problem Statement

npm trusted publishers can either publish straight to the registry or only stage a version, which then waits for the maintainer to approve it on npmjs.com with the passkey. Staged publishing is always allowed; direct publishing is an opt-in on the trusted publisher.

## Decision Drivers

* The maintainer asked to remove the manual release step
* The release workflow already refuses to publish when versions, CHANGELOG or tests disagree
* Only the maintainer can push tags today

## Considered Options

* Publish directly: the trusted publisher may publish to `latest`
* Staged publish with manual approval on npmjs.com

## Decision Outcome

Chosen option: "Publish directly", because the workflow's checks already gate the release and a manual approval would bring back the step this change removes.

### Consequences

* Good, because a pushed tag reaches npm without anyone logging in.
* Bad, because anyone who can push a `v*` tag can release a version.
* Neutral, because switching to staged publishing is one setting on npmjs.com and needs no workflow change.

### Confirmation

The trusted publisher on npmjs.com has "publish directly" ticked and dist-tag management off; the README "Releasing" section records the setting.

## Pros and Cons of the Options

### Staged publish with manual approval

* Good, because every version is approved by a person.
* Bad, because it keeps a manual step at the passkey.

## More Information

From design decision D2 of c008-release-workflow. Revisit when collaborators get push rights. Related: ADR 0048.
