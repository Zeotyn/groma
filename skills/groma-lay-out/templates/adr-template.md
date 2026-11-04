---
# MADR 4.0 frontmatter. status: proposed | rejected | accepted | deprecated | superseded by ADR-NNNN
status: {{status}}
date: {{today}}
decision-makers: {{decision_makers}}
consulted: {{consulted}}
informed: {{informed}}
# groma extension: files that show this decision in the code (required for retroactive ADRs)
evidence: [{{evidence}}]
---

# {{title: short problem and solved decision, e.g. "Use PostgreSQL for persistence"}}

## Context and Problem Statement

{{context: two or three sentences, or a question}}

## Decision Drivers

* {{driver}}

## Considered Options

* {{option_1}}
* {{option_2}}

## Decision Outcome

Chosen option: "{{option_1}}", because {{justification}}.

### Consequences

* Good, because {{positive}}
* Bad, because {{negative}}

### Confirmation

{{confirmation: how compliance is checked, e.g. a test, review or fitness function}}

## Pros and Cons of the Options

### {{option_1}}

* Good, because {{argument}}
* Bad, because {{argument}}

### {{option_2}}

* Good, because {{argument}}
* Bad, because {{argument}}

## More Information

{{more: links, related ADRs; for retroactive ADRs: "Derived by groma from existing code on {{today}}; confirm or reject."}}
