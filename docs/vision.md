---
title: Vision
status: draft
last_reviewed: 2026-11-04
review_after_days: 180
owner: Eugen Waldschmidt
sources: [README.md]
---

# Vision

## Problem

AI coding agents start every project without context: no stated purpose, no decisions on record, no methodology, and agent instruction files that differ per tool. In existing repositories the docs that do exist are often stale, and nobody knows which ones. Setting this up by hand takes hours and is rarely done.

## Target users

Developers who work with Claude Code, GitHub Copilot, Gemini CLI, Cursor or Codex and want a new or existing project laid out for agent work in one run.

## Goals

1. One `/groma` run takes an empty or existing folder to a documented, configured project.
2. Works for any language or stack without stack-specific code.
3. Re-running is safe and acts as an update.
4. Most extensions are a table row or a catalog entry, so contributing is easy.

## Non-goals

- Connecting to databases or other live systems.
- Rewriting, moving or deleting existing project files.
- Re-implementing what methodologies or third-party skills already do; groma calls their installers.
- Hosting a skill registry; the catalog only references upstream repositories.

## Success measures

| Measure | Target | How we check |
|---|---|---|
| Evals green on all fixtures | 5 of 5 | `scripts/test.sh evals` |
| Pre-existing files unchanged after a run | 100 % byte-identical | checksum invariant in `tests/invariant/` |
