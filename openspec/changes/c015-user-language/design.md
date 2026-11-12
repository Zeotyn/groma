## Context

Skills are written in English. Agents usually answer in the user's language, but nothing requires it, and printed hints from templates are English.

## Goals / Non-Goals

**Goals:**
- Everything groma says to the user is in the user's language.

**Non-Goals:**
- Translating repository files groma writes.
- Deciding the language of generated project docs (open question below).

## Decisions

### D1: One rule, stated where the user is addressed
A short "User language" rule in each skill that talks to the user: detect the language from the user's messages in the session; literal tokens (commands, paths, keys, ids) stay as they are.

Alternatives: a config key `language` (rejected: the session already shows the language, and a key goes stale); translate templates (rejected: many files to maintain; the agent translates on output).

## Open Questions

- In which language should generated project docs (vision, concept, …) be written: English always, the user's language, or a config choice? Out of scope for this change.

## Risks / Trade-offs

- [Mixed-language sessions] → use the language of the latest user message.
