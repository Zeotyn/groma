# greeting Specification

## Purpose

Greets a person by name so callers can show a friendly message.

## Requirements

### Requirement: Greet by name
The library SHALL return "Hello, <name>!" for a non-empty name and "Hello!" otherwise.

#### Scenario: Named greeting
- **WHEN** greet is called with "Ada"
- **THEN** it returns "Hello, Ada!"
