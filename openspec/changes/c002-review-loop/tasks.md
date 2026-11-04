## 1. Tests first

- [ ] 1.1 bats tests for `resolve-reviewer.sh` with stub CLIs (other vendor wins, probe failure falls back, pinned reviewer used, self-review marked)
- [ ] 1.2 bats tests for `review.sh` with stub CLIs (command per reviewer, read-only flags, table validation, one retry, unparseable fallback)
- [ ] 1.3 bats tests for `status.sh` on generated changes (ready to archive, stale, untested tasks, nothing open, reminders disabled)
- [ ] 1.4 Validator tests for `review` and `reminders` sections (valid defaults, unknown reviewer with suggestion, bad mode, missing section accepted)

## 2. Scripts

- [ ] 2.1 `skills/groma-loop/scripts/review.sh` incl. `--probe`
- [ ] 2.2 `skills/groma-loop/scripts/resolve-reviewer.sh`
- [ ] 2.3 `skills/groma-methodology/scripts/status.sh`

## 3. Config

- [ ] 3.1 Add `review` and `reminders` with defaults to `skills/groma/templates/config.yaml`
- [ ] 3.2 Extend `validate-config.sh` for both sections

## 4. Skill

- [ ] 4.1 `skills/groma-loop/references/review-prompt.md`: reviewer instructions and findings table format
- [ ] 4.2 `skills/groma-loop/references/methodology-adapters.md`: OpenSpec, Spec Kit, generic
- [ ] 4.3 `skills/groma-loop/templates/review-record.md`
- [ ] 4.4 `skills/groma-loop/SKILL.md`: phases, rounds, responses, stop criteria, tests gate, modes, escalation, records

## 5. Integration

- [ ] 5.1 AGENTS.md template: session-start status line and groma-loop pointer
- [ ] 5.2 `groma-agents`: offer the optional Claude SessionStart hook (additive / approval rule)
- [ ] 5.3 `groma` orchestrator: write review defaults; mention groma-loop in the summary's next action
- [ ] 5.4 README and CONTRIBUTING: review loop, modes, reviewer order, reminders
- [ ] 5.5 Regenerate the roadmap after implementation (`roadmap.sh`)

## 6. Eval

- [ ] 6.1 Eval fixture `loop-openspec` (small project with OpenSpec and one prepared change) and assertions: review records exist, every finding answered, change archived in autonomous mode
