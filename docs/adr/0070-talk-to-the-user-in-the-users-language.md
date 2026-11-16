---
status: proposed
date: 2026-11-16
decision-makers: Eugen Waldschmidt
evidence: [skills/groma/SKILL.md, skills/groma-agents/SKILL.md, tests/structure/check.py, tests/evals/assert.sh, tests/evals/answers/de-empty.md]
origin: c015-user-language#D1
---

# Talk to the user in the user's language, stated once in every skill

## Context and Problem Statement

The groma skills are written in English and say nothing about the language in which they talk to the user. Agents tend to answer in the user's language on their own, but nothing requires it, and texts that a skill prints from its own wording (the summary labels, the reasons next to a printed command) come out in English. A German user who runs `/groma` should get the interview, the summary and every hint in German. How does every skill step that addresses the user follow the user's language?

## Decision Drivers

* The session already shows which language the user writes in
* Commands, paths, config keys and ids must stay copyable
* Few lines to maintain; skill bodies stay short
* Files groma writes into the repository must not change with the person who ran it

## Considered Options

* One rule line in every skill, the same words everywhere
* A config key `language`
* Translated templates and messages

## Decision Outcome

Chosen option: "one rule line in every skill", because the agent translates on output and needs no data to do it.

Details:
- Every `SKILL.md` carries the line "**User language.** Talk to the user in the language of their latest message: questions, summaries, hints, warnings, escalations and the reasons for commands you print. Commands, paths, config keys and ids stay literal. Files you write, the findings report too, keep the language of their templates." In a mixed-language session the latest message decides.
- The line sits in the skill body, not in a shared reference file: it is one sentence, and a vendored file (ADR 0051) would cost a read in every skill. `tests/structure/check.py user-language` keeps the copies identical to the line in `skills/groma/SKILL.md`, which is the source to edit.
- The `/groma` summary translates its labels; paths and commands in it stay literal.
- Files groma writes stay as their templates say: config, AGENTS.md, findings reports, seed ADRs. A hint that goes both into the findings report and into the summary is English in the report and in the user's language in the summary.

### Consequences

* Good, because a user who writes German, French or any other language gets groma in that language without configuring anything.
* Good, because the same `.groma/config.yaml`, AGENTS.md and findings come out whoever runs groma.
* Bad, because eight skills repeat the same line; the structure check catches a copy that drifts.
* Bad, because the translation is the agent's: wording varies between runs and agents, and only an eval can observe it.
* Neutral, because the language of generated project docs (vision, concept, ...) is not decided here; see "More Information".

### Confirmation

`tests/structure/check.py` (`check_user_language`) and its unit tests check that every skill carries the line. The eval fixture `de-empty` (`tests/evals/answers/de-empty.md`, German prompt in `tests/evals/run.sh`) asserts a German summary and German questions, literal paths and commands, and English AGENTS.md, seed ADR, config keys and findings report. The eval discriminates weakly: its prompt is German too, so an agent may answer in German without the rule; it shows that the rule and German talk go together and that files stay English, not that the rule alone causes the German talk. The confirmation is partial until an eval run is recorded in the change's tasks.

## Pros and Cons of the Options

### A config key `language`

* Good, because the language is explicit and the same for every session.
* Bad, because the session already shows the language, and a key goes stale when another person runs groma on the same project.

### Translated templates and messages

* Good, because the wording is reviewed once per language.
* Bad, because every printed text exists once per language and must be kept in step, for languages nobody on the project reads.

## More Information

Decision D1 of `openspec/changes/c015-user-language/design.md`.

Open question, out of scope: in which language should the generated project docs (vision, concept, architecture, ...) be written: always English, the user's language, or a config choice? Today they follow their English templates, and interview answers may appear in the words the user gave them. A later change decides this and supersedes or extends this ADR.
