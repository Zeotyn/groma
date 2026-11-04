## Purpose

Says goodbye to a person by name, matching the style of the greeting.

## ADDED Requirements

### Requirement: Farewell by name
The library SHALL export `farewell(name)` that returns "Goodbye, <name>!" for a non-empty name and "Goodbye!" for an empty or missing name.

#### Scenario: Named farewell
- **WHEN** farewell is called with "Ada"
- **THEN** it returns "Goodbye, Ada!"

#### Scenario: Missing name
- **WHEN** farewell is called without a name
- **THEN** it returns "Goodbye!"
