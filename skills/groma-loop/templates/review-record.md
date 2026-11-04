---
change: {{change}}
phase: {{phase: propose | apply-<unit> | verify}}
round: {{round}} of {{max_rounds}}
author: {{author: agent[:model]}}
reviewer: {{reviewer: agent[:model] or self}}
reviewer_kind: {{kind: pinned | other-vendor | other-model | self-review}}
date: {{today}}
decision: {{decision: continue | stop-clean | stop-limit | escalate}}
---

# {{phase}} review, round {{round}}

Reviewer choice: {{reason from resolve-reviewer.sh}}

## Findings and responses

| id | severity | location | finding | suggestion | response |
|---|---|---|---|---|---|
| {{R1}} | {{severity}} | {{location}} | {{finding}} | {{suggestion}} | {{fixed: what changed / rejected: reason}} |

## Tests

{{apply only: test command, result before this round, result after the fixes}}

## Decision

{{one sentence: why the loop continues, stops or escalates}}
