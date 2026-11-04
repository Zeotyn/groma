Run the groma-loop skill in the current directory for the existing change
`c001-add-farewell` (OpenSpec). Settings are in .groma/config.yaml: autonomous
mode, reviewer pinned to claude:sonnet, one review round per phase, one review
unit for the whole change.

This is an automated evaluation: nobody can answer questions or approve gates.
Follow the skill exactly: tests gate before review, answer every finding with
fixed or rejected, write the review records, verify, then archive the change
with `openspec archive c001-add-farewell -y` (spec sync included). Do not use the
network except for the reviewer CLI call made by review.sh. Today is 2026-11-04.
