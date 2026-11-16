## ADDED Requirements

### Requirement: User language
Everything groma says to the user, including interview questions, the final summary, findings hints, escalations and printed commands with their reasons, SHALL be in the language the user writes in with the agent. Commands, paths, config keys and ids SHALL stay literal. Files written to the repository SHALL NOT change language because of this rule.

#### Scenario: German user
- **WHEN** the user answers the interview in German
- **THEN** the following questions and the final summary are in German, and the files groma writes are unchanged by the language
