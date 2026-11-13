# Manual test protocol: Claude Code bundles

Run before a release that changes a bundle or its skills. `tests/scripts/bundles.bats` already checks, without a model, that each bundle of `.claude-plugin/marketplace.json` installs exactly its skills. This checklist covers what needs a model: that a bundle works alone (change c009, spec scenario "Docs bundle only").

Time: about 15 minutes. Costs one survey run and one review-loop start.

## Setup

1. Use a throwaway config so your own plugins stay untouched: `export CLAUDE_CONFIG_DIR=/tmp/groma-bundles/cfg`, then log in with `claude` once.
2. Generate fixtures: `tests/fixtures/generate.sh /tmp/groma-bundles`
3. Add the marketplace from the release candidate: `claude plugin marketplace add <path-or-owner>/groma`

## Checks

| # | Bundle | Step | Expected | Result |
|---|---|---|---|---|
| 1 | `groma-docs` | `claude plugin install groma-docs@groma`, then `claude plugin details groma-docs@groma` | Skills (3): groma-detect, groma-lay-out, groma-survey | ☐ |
| 2 | `groma-docs` | In `/tmp/groma-bundles/node-prisma`: snapshot with `sh tests/invariant/checksum.sh snapshot <fx> <fx>.manifest`, then ask "survey this repository" | `docs/_groma/findings-<date>.md` exists with a findings table; no other groma skill was offered or needed | ☐ |
| 3 | `groma-docs` | `sh tests/invariant/checksum.sh verify <fx> <fx>.manifest` | no existing file changed | ☐ |
| 4 | `groma-loop` | `claude plugin uninstall groma-docs@groma`, `claude plugin install groma-loop@groma`, then in `/tmp/groma-bundles/loop-openspec` ask "groma-loop: propose a change that adds a health endpoint" | the loop starts; a step that needs groma-lay-out or groma-methodology names `npx skills add Zeotyn/groma --skill <name>` and is skipped, not failed | ☐ |

## Record

Add the date, the Claude Code version (`claude --version`) and the results to the release PR. Delete `/tmp/groma-bundles` afterwards.
