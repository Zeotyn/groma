# Manual test protocol: GitHub Copilot

Run once before every release. Copilot has no headless eval runner in this repo yet, so this checklist is the release gate for Copilot (milestone M001, task 2.2).

Time: about 30 minutes.

## Setup

1. Generate fixtures: `tests/fixtures/generate.sh /tmp/groma-copilot`
2. Install groma for Copilot from the release candidate:
   `copilot plugin marketplace add <path-or-owner>/groma` and `copilot plugin install groma@groma`
   (alternative: `npx skills add <path> --all -a github-copilot`)
3. Snapshot each fixture: `sh tests/invariant/checksum.sh snapshot /tmp/groma-copilot/<fx> /tmp/groma-copilot/<fx>.manifest`

## Checks

Run `/groma` in each fixture with the answers from `tests/evals/answers/<fx>.md`, then:

| # | Check | empty | node-prisma | java-flyway | django | go-no-db |
|---|---|---|---|---|---|---|
| 1 | `sh tests/evals/assert.sh <fx> <dir> <manifest>` passes | ☐ | ☐ | ☐ | ☐ | ☐ |
| 2 | groma announced "Step N of 8" for every step | ☐ | ☐ | ☐ | ☐ | ☐ |
| 3 | at most one question per message, with a recommended default | ☐ | ☐ | ☐ | ☐ | ☐ |
| 4 | `.github/copilot-instructions.md` points to AGENTS.md | ☐ | ☐ | ☐ | ☐ | ☐ |
| 5 | re-running `/groma` reports "nothing changed" and writes only a new findings report | ☐ | ☐ | ☐ | ☐ | ☐ |

## Record

Add the date, Copilot version (`copilot --version`) and results to the release PR.
