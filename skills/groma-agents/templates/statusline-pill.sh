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
# quotes (a path with a single quote in it does not work). In a plugin install
# the version folder of the plugin cache is a * outside the quotes, so that the
# line survives a plugin update; the highest version wins (sort -V):
#   "/Users/me/.claude/plugins/cache/groma/groma/"*"/skills/groma-methodology/scripts/next.sh"
# The pattern is expanded by a child sh, so the line behaves the same in a zsh
# or bash status line, also when nothing matches.
# shellcheck disable=SC2016  # the child sh expands its own variables
g=$(project_dir="${project_dir:-.}" sh -c 'set -- {{next_script_pattern}}; n=$(printf "%s\n" "$@" | sort -V 2>/dev/null | tail -n 1); n=${n:-$1}; [ ! -f "$n" ] || sh "$n" --short "$project_dir"' 2>/dev/null) || g=""; [ -z "$g" ] || printf ' \033[48;5;25m\033[38;5;255m ▶ %s \033[0m' "$g"
