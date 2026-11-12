# Eval: Claude Code Stop hook shows the next action (C007 task 4.1)

Date: 2026-11-12. Claude Code headless (`claude -p`), model haiku.

## Setup

A git repo with an upstream and 3 commits on `main` not pushed; `.groma/config.yaml` with `next.hook: on` and `reshow_minutes: 30`; `.claude/settings.local.json` from `skills/groma-agents/templates/claude-stop-hook.json` with the absolute path of `next-stop.sh`. `.claude/` and `.groma/` excluded through `.git/info/exclude`, so that the working tree is clean.

Run twice: `claude -p "Reply with the single word ok. Do not use any tools." --model haiku --output-format stream-json --verbose`

## Results

| Run | `▶ Next:` events in the stream | `num_turns` | Result |
|---|---|---|---|
| 1 | 1: `{"type":"system","subtype":"informational","content":"Stop says: ▶ Next: Push 3 commits on main: git push","level":"notice"}` | 1 | `ok` |
| 2 (same suggestion, within 30 minutes) | 0 | 1 | `ok` |

The message is shown to the user as a notice, no extra agent turn starts, and the debounce suppresses the repeat.
