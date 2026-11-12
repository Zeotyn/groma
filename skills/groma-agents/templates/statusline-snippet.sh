#!/bin/sh
# groma next action as a Claude Code status line pill: "▶ push 3".
#
# Existing status line script: add this one line where the script builds its
# output, with $project_dir set to the session's project directory
# (workspace.project_dir in the JSON on stdin):
#   n=$(sh "{{next_script_absolute}}" --short "$project_dir") && [ -n "$n" ] && printf ' ▶ %s' "$n"
#
# No status line yet: save this file, for example as ~/.claude/groma-statusline.sh,
# and add to ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "sh ~/.claude/groma-statusline.sh" }
# Claude Code passes the session as JSON on stdin; workspace.project_dir is the project.
dir=$(sed -n 's/.*"project_dir"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
n=$(sh "{{next_script_absolute}}" --short "${dir:-.}" 2>/dev/null) || n=""
[ -z "$n" ] || printf '▶ %s' "$n"
