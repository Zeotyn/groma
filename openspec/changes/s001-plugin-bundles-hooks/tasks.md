## 1. Runs

- [ ] 1.1 Bundles: throwaway marketplace with two or three plugins of differing skill subsets from one repository; record which layouts install the right skills, in `tests/manual/claude-plugin-bundles-<date>.md`
- [ ] 1.2 Plugin hooks: plugin with `hooks/hooks.json` (`SessionStart`, `Stop`); confirm no settings edit is needed and record the environment a hook command sees
- [ ] 1.3 SessionStart: plain stdout versus `hookSpecificOutput.additionalContext`, for startup, resume, clear and compact; record what the agent can quote back
- [ ] 1.4 Copilot: whether a Copilot CLI plugin can carry hooks; record the result or "not supported"

## 2. Outcome

- [ ] 2.1 ADR with the answers and the layout for bundles and plugin hooks, `origin: s001-plugin-bundles-hooks`
- [ ] 2.2 Update `c009-marketplace-bundles` and `c014-plugin-next-hooks` design notes, or open a follow-up change, where an answer differs from their plan
