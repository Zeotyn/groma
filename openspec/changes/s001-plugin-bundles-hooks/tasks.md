## 1. Runs

- [x] 1.1 Bundles: throwaway marketplace with two or three plugins of differing skill subsets from one repository; record which layouts install the right skills, in `tests/manual/claude-plugin-bundles-<date>.md`
- [x] 1.2 Plugin hooks: plugin with `hooks/hooks.json` (`SessionStart`, `Stop`); confirm no settings edit is needed and record the environment a hook command sees
- [x] 1.3 SessionStart: plain stdout versus `hookSpecificOutput.additionalContext`, for startup, resume, clear and compact; record what the agent can quote back
- [x] 1.4 Copilot: whether a Copilot CLI plugin can carry hooks; record the result or "not supported"
- [x] 1.5 Plugin off per project: how to switch an installed plugin off for one project only; record the mechanism for the C016 hint

## 2. Outcome

- [x] 2.1 ADR with the answers and the layout for bundles and plugin hooks, `origin: s001-plugin-bundles-hooks`
- [x] 2.2 Update `c009-marketplace-bundles` and `c014-plugin-next-hooks` design notes, or open a follow-up change, where an answer differs from their plan

## 3. Docs

- [x] Docs: `docs/architecture.md` unchanged, because the spike adds a manual run protocol and changes no component; C009 and C014 update the architecture when they build
- [x] Docs: `docs/code-style.md` unchanged, because a Markdown run protocol adds no code convention
- [x] Docs: `docs/roadmap.md` unchanged, because it was regenerated and no change state or task count moved
