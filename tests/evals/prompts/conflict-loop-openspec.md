Run the groma-loop skill in the current directory for the existing change
`c001-add-farewell` (OpenSpec). Settings are in .groma/config.yaml: autonomous
mode, reviewer pinned to claude:sonnet, one review round per phase, one review
unit for the whole change, git defaults (integrate: rebase, push: ask).

The repository is already on the change branch `c001-add-farewell`; `main` has
moved on since the branch was created.

This is an automated evaluation: nobody can answer questions or approve gates.
Follow the skill exactly, including its git steps: commit the review unit after
green tests and a clean review, archive the change with
`openspec archive c001-add-farewell -y` (spec sync included), commit the
archive, then integrate with the configured strategy. When the integration
conflicts, abort it as the skill says and stop with the escalation message that
names the conflicting paths; do not resolve the conflict. Do not use the
network except for the reviewer CLI call made by review.sh. Today is 2026-11-04.
