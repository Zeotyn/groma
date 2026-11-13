#!/bin/sh
# groma next action as one pill for a status line that already renders pills: " ▶ push 3 ".
#
# Snippet only: groma never edits a status line. Paste the last line of this
# file where your status line script prints its pills, with $project_dir set to
# the session's project directory (workspace.project_dir in the JSON on stdin).
# The pill is white on blue (256-color codes 255 and 25): change the two numbers
# to match its neighbours. Nothing is printed when there is no next action.
#
# {{next_script_pattern}} is the path of groma-methodology's next.sh in double
# quotes. In a plugin install the version folder of the plugin cache is a * outside
# the quotes, so that the line survives a plugin update; the loop keeps the last match:
#   "/Users/me/.claude/plugins/cache/groma/groma/"*"/skills/groma-methodology/scripts/next.sh"
# shellcheck disable=SC1083,SC2043  # the placeholder becomes a quoted path, with a * in a plugin install
for g in {{next_script_pattern}}; do :; done; g=$(sh "$g" --short "${project_dir:-.}" 2>/dev/null) || g=""; [ -z "$g" ] || printf ' \033[48;5;25m\033[38;5;255m ▶ %s \033[0m' "$g"
