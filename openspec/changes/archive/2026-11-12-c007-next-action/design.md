## Context

`status.sh` (with F002) lists every reminder: change states, milestone gates, uncommitted and unpushed work, pending ADRs. It takes about 0.5 s on this repository and prints many lines. Claude Code offers two display-only places: the status line, a command the user owns and that runs very often, and the Stop hook's `systemMessage`, shown once after each answer. Other CLIs have stop-like hooks with different channels. Research on 2026-11-04 found:
- Copilot `agentStop` decides only `block` or `allow`.
- Gemini `AfterAgent` has an advisory `systemMessage` whose support depends on the version.
- Cursor `stop` has a `followup_message` that goes to the agent.
- Codex `Stop` is behind a feature flag and a trust prompt.

Only Claude and Copilot are testable here.

## Goals / Non-Goals

**Goals:**
- One line, the right one, deterministic, local, fast.
- Visible without the user asking: a status-line pill and a debounced message after answers.
- Never changes what the agent does.

**Non-Goals:**
- Network signals (CI, PR state).
- Running tests to detect red builds.
- Editing user-owned configuration (global settings, status line scripts).

## Decisions

### D1: Display-only channels, never steering
Hooks write to the user only (`systemMessage` in Claude Code). Anything that blocks, retries or sends a follow-up to the agent is forbidden. Those channels create extra agent turns, cost tokens, and can loop.

Alternatives: steer the agent through a follow-up channel so it acts on the next step itself (rejected: loops and uninvited work, and the user decides what comes next); inject context through UserPromptSubmit (rejected: costs tokens every turn, and the model may drop it).

### D2: Ladder in a script, built on `status.sh`
`next.sh` reads `status.sh` output plus two git checks: a rebase or merge in progress (`.git/rebase-merge`, `.git/rebase-apply`, `.git/MERGE_HEAD`) and `git.push`. It maps the lines to rungs and prints the first one. The rungs and their texts sit in a table at the top of the script, so the order is visible and testable.

Alternatives: a second independent implementation of the checks (rejected: two sources of truth for reminders); let the agent pick the next step (rejected: not deterministic and costs tokens).

### D3: Cache on `HEAD`, working tree, refs, config and changes folder
The cache key is the git object hash (`git hash-object --stdin`) of the following, concatenated:
- `git rev-parse HEAD`
- `git status --porcelain`
- the local and remote branch heads (`git for-each-ref refs/heads refs/remotes`)
- the content of `.groma/config.yaml`

A file in the changes folder newer than the cache file (`find -newer`) also invalidates it.

A hit returns the cached result. A miss runs the ladder and writes `.groma/.cache/next`. The script creates `.groma/.cache/.gitignore` with `*` if absent, so the folder ignores itself. The `.groma/` folder belongs to groma, so ADR 0006 allows the write.

Implementation notes (apply):
- The key also covers `git for-each-ref refs/heads refs/remotes`: a `git push` changes neither `HEAD` nor the working tree, so without the refs the unpushed rung would stay cached after a push.
- The cache file `.groma/.cache/next` holds plain lines (key, rung, short, long) instead of JSON, so the shell never parses JSON; `--json` is rendered on output.
- The rebase or merge check (rung 1) runs before the cache lookup and is never cached.
- A self-ignoring `.groma/.cache/.gitignore` replaces the planned `.groma/.gitignore`: creating `.groma/.gitignore` showed up as an untracked file, so the first run reported its own write as uncommitted work. The hook state moved into the same folder.
- The cache is used only when `.groma/` exists, so `next.sh` writes nothing into a project groma did not set up.

Alternatives: time-based cache (rejected: stale right after a commit, which is exactly when the suggestion changes); no cache (rejected: the status line calls the script on every refresh).

### D4: Status line by snippet only
The status line is user-owned and often global (`~/.claude/statusline.sh`). groma prints a snippet in the summary, for example `n=$(sh <path>/next.sh --short "$cwd") && [ -n "$n" ] && parts+=("▶ $n")`, and a minimal standalone status-line command for users without one.

Alternatives: write the status line config when none exists (rejected: global settings are outside the project, and ADR 0006 covers the project only, so groma's write scope must not grow to `~`); skip the status line (rejected: it is the least noisy display).

### D5: Debounce state in `.groma/.cache/next-shown`
The Stop hook command runs `next.sh --long`. It compares the result with `.groma/.cache/next-shown`, which stores the line and an epoch. It prints `{"systemMessage": "▶ Next: …"}` when the line differs or when the stored epoch is older than `reshow_minutes`, and then updates the file. Otherwise it prints nothing. An empty result clears the file.

Alternatives: show after every answer (rejected: banner blindness); show only at session start (rejected: the SessionStart hook already covers that).

### D6: Adapters in `agents.yaml`, Copilot decided by spike
Each agent gets `hook: {status, event, config, format}`:
- claude: `stable`, `Stop`, `.claude/settings.local.json`, `systemMessage`.
- copilot: `spike` until task 1.1, which tests whether `agentStop` stdout or a message field reaches the user without another turn. Yes → `stable` with that format, no → `none`.
- gemini: `experimental`, `AfterAgent`, `systemMessage`.
- codex: `experimental`, `Stop`, needs `codex_hooks = true` and trust.
- cursor: `none`.

Spike result (task 1.1, `tests/manual/copilot-agentstop-2026-11-12.md`): Copilot ignores plain stdout and `systemMessage` on `agentStop`; stderr with exit code 2 is shown to the user as `! <text>` without a new turn (headless, CLI 1.0.105). Copilot is `experimental` with format `stderr-exit2` (`next-stop.sh --stderr`) until the interactive TUI is checked.

Alternatives: hard-code per-agent logic in groma-agents (rejected: ADR 0004); support only Claude (rejected: the fallback costs nothing to keep open for others).

## Risks / Trade-offs

- [CLI hook formats change] → the adapter data in one table plus a structure check. `experimental` entries are marked untested.
- [Short form loses detail] → the long form is one command away (`npx groma-cli next`).
- [Status-line refresh runs `git status` often] → the cache keeps hits cheap. `git status --porcelain` is the floor, measured on large repos in task 2.4.
- [A wrong rung order annoys] → the order is a table, tested, and documented in the ADR for D2.

## Migration Plan

- `upgrades.md` row 0.3.0: in update mode, offer the hook and the snippet once, and put the AGENTS.md "Session end" section into the findings report as a snippet; an existing AGENTS.md is never edited (ADR 0006), even one groma created.
- `next.hook: off` by default. groma sets `on` only after the user agrees.

## Open Questions

- Should `--short` include an icon chosen per rung (for example ⬆ for push)? Deferred to the status-line snippet. Users style their own lines.
