## Context

`groma-cli` is published from the maintainer's terminal: the npm account uses a passkey, and `npm publish` from an agent shell fails with EOTP, even with `--auth-type=web`, because there is no TTY. npm trusted publishing lets a CI workflow publish through OIDC instead: npm trusts a named repository and workflow file, and the workflow proves its identity with a short-lived GitHub token. The maintainer configured the trusted publisher on npmjs.com on 2026-11-12: repository `Zeotyn/groma`, workflow `release.yml`, direct publish allowed, dist-tag management off, publishing access set to "require 2FA and disallow bypass tokens".

## Goals / Non-Goals

**Goals:**
- A pushed `v<version>` tag is the whole release action; nobody needs a terminal for npm.
- Nothing publishes when the tag, the versions or the CHANGELOG disagree, or when tests fail.
- No npm secret in the repository.

**Non-Goals:**
- Creating the tag or bumping versions automatically; the release preparation stays a reviewed commit.
- Publishing the Claude plugin, skills or other manifests; they ship from the repository itself.
- Pre-release channels (`next`, `beta`).

## Decisions

### D1: Trusted publishing from GitHub Actions
The workflow requests `id-token: write`, installs npm 11.5.1 or newer (the first version with trusted publishing), and runs `npm publish --provenance --access public`. No `NODE_AUTH_TOKEN`, no `.npmrc` with a token. The npm side knows only `Zeotyn/groma` + `release.yml`, so a renamed workflow file stops publishing, which is intended.

Alternatives: an npm automation token as a repository secret (rejected: a long-lived secret that bypasses 2FA, and the account now disallows bypass tokens); keep publishing by hand (rejected: the release then depends on one person at one machine, which is the problem this change removes).

### D2: Publish directly, not staged
The trusted publisher may publish straight to `latest`. npm's staged publishing would hold each version until the maintainer approves it on npmjs.com with the passkey.

Alternatives: staged publish with manual approval (rejected for now: it keeps a manual step, which the maintainer asked to remove; it stays available by unticking "publish directly" on npmjs.com, and the workflow needs no change for it).

### D3: One check script for CI and local use
`scripts/release-check.sh <tag>` prints one line per problem and exits non-zero on any: tag not `v<semver>`, a manifest version different from the tag (it names the file), no `## [<version>]` section in `CHANGELOG.md`. It reads the same manifest list as `tests/structure/check.py` `check_versions`. The workflow runs it before the tests; the maintainer can run it before pushing the tag. The GitHub release notes are cut from the same CHANGELOG section by the script's `--notes` mode.

No ADR: this is an implementation detail of D1 without a real alternative.

## Risks / Trade-offs

- [Anyone with push rights to tags can publish] → today only the maintainer has push rights; switch to staged publishing (D2) if collaborators join.
- [The first trusted publish is untested until `v0.3.0`] → `release-check.sh` and the tests run first; if the publish step fails, the tag stays and the maintainer can publish 0.3.0 by hand as before.
- [npm's OIDC requirements change] → the workflow pins `npm@11` and Node 22; a failing publish is visible in the Actions run and does not affect the repository.
