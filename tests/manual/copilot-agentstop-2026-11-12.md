# Spike: Copilot CLI `agentStop` as a display-only channel (C007 task 1.1)

Date: 2026-11-12. Copilot CLI 1.0.105, headless (`copilot -p`), model claude-haiku-4.5.

## Question

Can an `agentStop` hook show one line to the user without starting another agent turn and without the text reaching the model?

## Setup

Throwaway git repo, hook file `.github/hooks/h.json`:

```json
{"version":1,"hooks":{"agentStop":[{"type":"command","bash":"./hook.sh <variant>","timeoutSec":10}]}}
```

`hook.sh` appends a line to `hook.log` on every call, then runs one of the variants below. Each variant was run once with:
`copilot -p "Reply with the single word ok" --allow-all-tools --trust-folder --model claude-haiku-4.5`

## Results

| Variant | Shown to user | `agentStop` calls | Reached the model |
|---|---|---|---|
| plain text on stdout | no | 1 | no sign |
| `{"systemMessage": "..."}` on stdout | no (ignored) | 1 | no sign |
| text on stderr, exit 2 | yes, as `! <text>` on stderr | 1 | no sign |

Docs (https://docs.github.com/en/copilot/reference/hooks-configuration): `agentStop` output JSON knows only `decision` (`block`/`allow`) and `reason`; `block` feeds `reason` back to the model as the next prompt and is therefore forbidden for groma (D1). Exit 2 is a general "warning" exit: stderr is shown to the user and the run continues.

## Verdict

A display-only channel exists: stderr with exit code 2. `--trust-folder` loads project hooks in headless mode.

Not verified: rendering in the interactive TUI, and whether exit 2 is logged as a hook warning. That is why copilot's adapter is `experimental` (format `stderr-exit2`) instead of `stable`. Promote it after a manual check in the TUI.
