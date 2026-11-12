---
status: proposed
date: 2026-11-12
decision-makers: Eugen Waldschmidt
evidence: [.github/workflows/release.yml, scripts/release-check.sh, tests/scripts/release-check.bats]
origin: c008-release-workflow#D1
---

# Publish to npm through trusted publishing

## Context and Problem Statement

`groma-cli` was published from the maintainer's terminal. The npm account uses a passkey, and `npm publish` from an agent shell fails with EOTP because there is no terminal to answer it. Every release therefore waited for one person at one machine.

## Decision Drivers

* A release should not need a person at a terminal
* No long-lived npm secret in the repository
* Nothing publishes when versions, CHANGELOG or tests disagree

## Considered Options

* npm trusted publishing from a GitHub Actions workflow on `v*` tags (OIDC, `id-token: write`)
* An npm automation token as a repository secret
* Keep publishing by hand

## Decision Outcome

Chosen option: "npm trusted publishing", because the workflow proves its identity with a short-lived OIDC token that npm accepts only for `Zeotyn/groma` and `release.yml`, so there is no secret to leak and no manual step.

### Consequences

* Good, because a pushed tag is the whole release action.
* Good, because every published version carries npm provenance.
* Good, because the npm account can disallow bypass tokens entirely.
* Bad, because renaming `release.yml` silently stops publishing until npmjs.com is updated.
* Bad, because the first trusted publish is only proven by the first real release.

### Confirmation

`scripts/release-check.sh` and its bats tests cover the pre-publish checks. The workflow references no `NPM_TOKEN` or `NODE_AUTH_TOKEN`.

## Pros and Cons of the Options

### npm automation token

* Bad, because it is a long-lived secret that bypasses 2FA, and the account now disallows bypass tokens.

### Publish by hand

* Bad, because releases depend on one person at one machine.

## More Information

From design decision D1 of c008-release-workflow. Related: ADR 0049.
