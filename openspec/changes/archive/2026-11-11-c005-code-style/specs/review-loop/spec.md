## ADDED Requirements

### Requirement: Style in the loop
groma-loop SHALL run the check commands from the code-style doc's tools table together with the tests in the tests gate; a failing check SHALL count as red tests. The review prompt SHALL include the code-style doc as project rules: violating a tool rule is a high finding, violating a convention is a medium finding.

#### Scenario: Lint fails during apply
- **WHEN** a task group's tests pass and `npm run lint` fails
- **THEN** no review runs; the author fixes and reruns within `test_retries`, then escalates with the lint output
