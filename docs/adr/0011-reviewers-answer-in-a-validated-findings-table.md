---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-loop/scripts/review.sh, skills/groma-loop/references/review-prompt.md, skills/groma-loop/templates/review-record.md]
origin: c002-review-loop#D3
---

# Require reviewer findings in a fixed Markdown table

## Context and Problem Statement

The author must answer every review finding, so the loop needs findings in a form it can parse, whichever model wrote them.

## Considered Options

* A fixed table `| id | severity | location | finding | suggestion |`, validated by `review.sh`

No alternatives were recorded.

## Decision Outcome

Chosen option: "A fixed table validated by `review.sh`", because it makes findings parseable. On a malformed answer `review.sh` retries once with a format reminder, then records the raw answer and treats it as one medium finding "unparseable review".

### Consequences

* Good, because a bad answer never stops the loop and never disappears.
* Bad, because one retry costs an extra reviewer call.

### Confirmation

`tests/scripts/review.bats` covers table validation and the retry.

## More Information

From design decision D3 of c002-review-loop. No alternatives were recorded. Related: ADR 0010.
