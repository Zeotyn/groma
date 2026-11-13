---
title: Risks and technical debt
status: draft
last_reviewed: 2026-11-13
review_after_days: 60
owner: Eugen Waldschmidt
sources: [skills/groma-skills/catalog.yaml, tests/invariant/, install.sh, gemini-extension.json, .claude-plugin/, .codex-plugin/, .cursor-plugin/]
---

# Risks and technical debt

| Id | Risk or debt | Likelihood | Impact | Mitigation | Owner | Status |
|---|---|---|---|---|---|---|
| R1 | Upstream skills rename, move or vanish | medium | medium | Catalog pins a `ref`; CI checks that sources resolve | Eugen Waldschmidt | open |
| R2 | An agent ignores the "never overwrite" rule | low | high | Refusal rule in every writing skill; checksum invariant in tests and evals | Eugen Waldschmidt | open |
| R3 | Gemini, Cursor and Codex manifests drift because they are untested | medium | medium | Marked best effort in README; schema checks for all manifests | Eugen Waldschmidt | open |
| R4 | Third-party installers become interactive or change flags | medium | medium | Pinned versions; fall back to `.groma/install.sh` on non-zero exit | Eugen Waldschmidt | open |
| R5 | Decisions D1-D11 exist only in an unarchived change design, not as ADRs | high | medium | Review proposed ADRs 0003-0008 | Eugen Waldschmidt | open |
| R6 | CHANGELOG has no release entry matching manifest version 0.1.0 | high | low | Cut the `[0.1.0]` entry when M001 ships | Eugen Waldschmidt | closed |
| R7 | An agent ignores a bundle's `skills` list and installs every skill (Copilot CLI untested; a later Claude Code release could change it) | medium | low | `tests/scripts/bundles.bats` installs each bundle with the latest Claude Code in CI; README marks Copilot untested and recommends `groma@groma` there | Eugen Waldschmidt | open |

Findings from groma surveys (stale docs, data-model drift, missing ADRs) can be copied here once confirmed.
