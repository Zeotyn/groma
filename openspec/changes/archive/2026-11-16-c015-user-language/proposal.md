Milestone: m004

## Why

No groma skill says in which language it talks to the user. It works today only because agents tend to follow the user's language on their own. A German user who runs `/groma` should get the interview, the summary and every hint in German, including the commands groma prints instead of running them, with their reasons.

## What Changes

- A cross-cutting rule in every user-facing skill step: questions, summaries, findings hints, escalations and printed commands with reasons are in the language the user writes in with their agent. Commands, paths and config keys stay literal.
- Files groma writes into the repository are unchanged by this rule: groma's own artifacts stay English; the language of generated project docs is out of scope and recorded as an open question.
- An eval runs the empty fixture with German interview answers and asserts German questions and summary.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `orchestration`: groma talks to the user in the user's language.

## Docs impact

`docs/concept.md` crosscutting concepts (user language); ADR for the rule and the open docs-language question.

## Impact

`skills/groma/SKILL.md` and the user-facing steps of the other skills (a single shared line, vendored per R001 if needed); one eval answers file.
