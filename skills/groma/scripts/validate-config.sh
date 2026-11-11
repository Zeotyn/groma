#!/bin/sh
# Validate a .groma/config.yaml. Read-only.
#
# Usage: validate-config.sh [config] [--catalog <catalog.yaml>]
#   config defaults to .groma/config.yaml
#   with --catalog, skill ids and categories are checked against the catalog
#
# Output: error|warning<TAB>line <n><TAB><message>, then a summary line.
# Exit codes: 0 valid, 1 errors, 3 config uses a newer schema than supported.
#
# Supports the YAML subset groma writes: block mappings, inline lists [a, b],
# block lists (- item) and # comments.
set -eu

SUPPORTED_SCHEMA=1
CFG=.groma/config.yaml
CATALOG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --catalog) CATALOG=$2; shift 2 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) CFG=$1; shift ;;
  esac
done
[ -f "$CFG" ] || { echo "config not found: $CFG" >&2; exit 2; }
[ -z "$CATALOG" ] || [ -f "$CATALOG" ] || { echo "catalog not found: $CATALOG" >&2; exit 2; }

# Flatten YAML into: path<TAB>value<TAB>line ; lists become comma-joined values.
flatten() {
  awk '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function strip_comment(s,   i, c, q) {
      q = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (q == "" && (c == "\"" || c == "\047")) q = c
        else if (q != "" && c == q) q = ""
        else if (q == "" && c == "#" && (i == 1 || substr(s, i - 1, 1) ~ /[ \t]/)) return substr(s, 1, i - 1)
      }
      return s
    }
    function unq(s) { s = trim(s); if (s ~ /^".*"$/ || s ~ /^\047.*\047$/) s = substr(s, 2, length(s) - 2); return s }
    function path(d,   p, i) { p = ""; for (i = 1; i <= d; i++) p = p (p == "" ? "" : ".") key[i]; return p }
    {
      raw = strip_comment($0)
      if (trim(raw) == "") next
      match(raw, /^ */); ind = RLENGTH
      line = trim(raw)
      if (line ~ /^-( |$)/) {            # block list item for the last open key
        item = unq(substr(line, 2))
        val[lastpath] = (val[lastpath] == "" ? item : val[lastpath] "," item)
        next
      }
      while (depth > 0 && ind <= indent[depth]) depth--
      if (index(line, ":") == 0) next
      k = trim(substr(line, 1, index(line, ":") - 1))
      v = trim(substr(line, index(line, ":") + 1))
      depth++; key[depth] = k; indent[depth] = ind
      p = path(depth); ln[p] = NR; order[++n] = p; val[p] = ""
      if (v == "") { lastpath = p; next }   # mapping or block list follows
      if (v ~ /^\[.*\]$/) {
        v = substr(v, 2, length(v) - 2); m = split(v, a, ","); out = ""
        for (i = 1; i <= m; i++) { x = unq(a[i]); if (x != "") out = (out == "" ? x : out "," x) }
        val[p] = out
      } else val[p] = unq(v)
      depth--                              # scalars have no children
    }
    END { for (i = 1; i <= n; i++) { p = order[i]; printf "%s\t%s\t%s\n", p, val[p], ln[p] } }
  ' "$1"
}

TAB=$(printf '\t')
FLAT=$(flatten "$CFG")
errors=0 warnings=0

get() { printf '%s\n' "$FLAT" | awk -F "$TAB" -v k="$1" '$1 == k { print $2; exit }'; }
line_of() { printf '%s\n' "$FLAT" | awk -F "$TAB" -v k="$1" '$1 == k { print $3; exit }'; }
has() { printf '%s\n' "$FLAT" | awk -F "$TAB" -v k="$1" '$1 == k { f = 1 } END { exit !f }'; }
report() { # level key message
  l=$(line_of "$2"); l=${l:-0}
  printf '%s%sline %s%s%s\n' "$1" "$TAB" "$l" "$TAB" "$3"
  if [ "$1" = error ]; then errors=$((errors + 1)); else warnings=$((warnings + 1)); fi
}
in_set() { # value "a b c"
  for x in $2; do [ "$x" = "$1" ] && return 0; done
  return 1
}
closest() { # word "candidates"
  echo "$2" | tr ' ' '\n' | awk -v w="$1" '
    function lev(a, b,   i, j, la, lb, d, cost, x, y, z) {
      la = length(a); lb = length(b)
      for (i = 0; i <= la; i++) d[i, 0] = i
      for (j = 0; j <= lb; j++) d[0, j] = j
      for (i = 1; i <= la; i++) for (j = 1; j <= lb; j++) {
        cost = substr(a, i, 1) == substr(b, j, 1) ? 0 : 1
        x = d[i - 1, j] + 1; y = d[i, j - 1] + 1; z = d[i - 1, j - 1] + cost
        d[i, j] = (x < y ? (x < z ? x : z) : (y < z ? y : z))
      }
      return d[la, lb]
    }
    NF { s = lev(w, $0); if (best == "" || s < bs) { best = $0; bs = s } }
    END { if (best != "" && bs <= 3) print best }'
}

# --- schema ------------------------------------------------------------------
schema=$(get schema)
if [ -z "$schema" ]; then
  report error schema "missing required key 'schema'"
else
  case "$schema" in ''|*[!0-9]*) report error schema "schema must be a number, got '$schema'" ;; esac
  if [ "$schema" -gt "$SUPPORTED_SCHEMA" ] 2>/dev/null; then
    report error schema "config uses schema $schema, this groma supports up to $SUPPORTED_SCHEMA: update groma (npx skills update, or claude plugin update groma)"
    printf 'summary%serrors=%d%swarnings=%d\n' "$TAB" "$errors" "$TAB" "$warnings"
    exit 3
  fi
fi

# --- required keys and enums -----------------------------------------------------
for k in initialized_with project_type methodology agents skills docs conventions; do
  has "$k" || report error "$k" "missing required key '$k'"
done
for k in $(printf '%s\n' "$FLAT" | cut -f1 | awk -F. '{ print $1 }' | sort -u); do
  in_set "$k" "schema initialized_with project project_type project_type_override methodology workflow agents agents_via_plugin skills docs conventions review reminders git steps" \
    || report warning "$k" "unknown top-level key '$k'"
done
v=$(get project_type); [ -z "$v" ] || in_set "$v" "greenfield brownfield" || report error project_type "project_type must be greenfield or brownfield, got '$v'"
v=$(get project_type_override); [ -z "$v" ] || in_set "$v" "none greenfield brownfield" || report error project_type_override "project_type_override must be none, greenfield or brownfield, got '$v'"
v=$(get methodology); [ -z "$v" ] || in_set "$v" "openspec spec-kit bmad gsd none" || report error methodology "unknown methodology '$v' (allowed: openspec, spec-kit, bmad, gsd, none)$(c=$(closest "$v" "openspec spec-kit bmad gsd"); [ -z "$c" ] || printf ', did you mean %s?' "$c")"
for a in $(get agents | tr ',' ' '); do
  in_set "$a" "claude copilot gemini cursor codex" || report error agents "unknown agent '$a' (allowed: claude, copilot, gemini, cursor, codex)$(c=$(closest "$a" "claude copilot gemini cursor codex"); [ -z "$c" ] || printf ', did you mean %s?' "$c")"
done
for a in $(get agents_via_plugin | tr ',' ' '); do
  in_set "$a" "claude copilot gemini cursor codex" || report error agents_via_plugin "unknown agent '$a' in agents_via_plugin (allowed: claude, copilot, gemini, cursor, codex)"
done
v=$(get initialized_with); [ -z "$v" ] || echo "$v" | grep -Eq '^groma@[0-9]+\.[0-9]+\.[0-9]+' || report error initialized_with "initialized_with must look like groma@1.2.3, got '$v'"
for s in $(printf '%s\n' "$FLAT" | cut -f1 | grep '^steps\.' || true); do
  v=$(get "$s"); in_set "$v" "done pending skipped" || report error "$s" "$s must be done, pending or skipped, got '$v'"
done
for o in $(get docs.optional | tr ',' ' '); do
  in_set "$o" "constraints quality security operations stakeholders" || report error docs.optional "unknown optional doc '$o'"
done
v=$(get docs.gate); [ -z "$v" ] || in_set "$v" "off remind review strict" || report error docs.gate "docs.gate must be off, remind, review or strict, got '$v'$(c=$(closest "$v" "off remind review strict"); [ -z "$c" ] || printf ', did you mean %s?' "$c")"
v=$(get docs.adr_from); [ -z "$v" ] || in_set "$v" "design-alternatives marked off" || report error docs.adr_from "docs.adr_from must be design-alternatives, marked or off, got '$v'$(c=$(closest "$v" "design-alternatives marked off"); [ -z "$c" ] || printf ', did you mean %s?' "$c")"

# --- review and reminders (optional sections) ----------------------------------------
is_int() { case "$1" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }
v=$(get review.mode); [ -z "$v" ] || in_set "$v" "autonomous gated" || report error review.mode "review.mode must be autonomous or gated, got '$v'"
v=$(get review.stop_when); [ -z "$v" ] || in_set "$v" "no-high no-findings" || report error review.stop_when "review.stop_when must be no-high or no-findings, got '$v'"
for ph in propose apply; do
  r=$(get "review.$ph.reviewer")
  if [ -n "$r" ] && [ "$r" != auto ] && [ "$r" != self ]; then
    ag=${r%%:*}
    in_set "$ag" "claude copilot gemini codex" || report error "review.$ph.reviewer" "unknown reviewer '$r' in review.$ph.reviewer (auto, self or claude|copilot|gemini|codex[:model])$(c=$(closest "$ag" "claude copilot gemini codex"); [ -z "$c" ] || printf ', did you mean %s?' "$c")"
  fi
  m=$(get "review.$ph.max_rounds")
  if [ -n "$m" ] && { ! is_int "$m" || [ "$m" -lt 1 ] || [ "$m" -gt 10 ]; }; then
    report error "review.$ph.max_rounds" "review.$ph.max_rounds must be a number from 1 to 10, got '$m'"
  fi
done
v=$(get review.apply.per); [ -z "$v" ] || in_set "$v" "task task-group change" || report error review.apply.per "review.apply.per must be task, task-group or change, got '$v'"
v=$(get review.apply.test_retries)
if [ -n "$v" ] && { ! is_int "$v" || [ "$v" -gt 10 ]; }; then report error review.apply.test_retries "review.apply.test_retries must be a number from 0 to 10, got '$v'"; fi
for b in archive_when_done untested_tasks uncommitted unpushed; do
  v=$(get "reminders.$b"); [ -z "$v" ] || in_set "$v" "true false" || report error "reminders.$b" "reminders.$b must be true or false, got '$v'"
done
v=$(get reminders.stale_change_days)
if [ -n "$v" ] && ! is_int "$v"; then report error reminders.stale_change_days "reminders.stale_change_days must be a number >= 0, got '$v'"; fi

# --- git workflow (optional section; missing keys mean rebase, true, conventional, ask) ----
enum() { # key "allowed values" "allowed, as text"
  v=$(get "$1"); [ -z "$v" ] || in_set "$v" "$2" || report error "$1" "$1 must be $3, got '$v'$(c=$(closest "$v" "$2"); [ -z "$c" ] || printf ', did you mean %s?' "$c")"
}
enum git.integrate "rebase merge squash" "rebase, merge or squash"
enum git.commits "conventional free" "conventional or free"
enum git.push "ask auto never" "ask, auto or never"
v=$(get git.branch_per_change); [ -z "$v" ] || in_set "$v" "true false" || report error git.branch_per_change "git.branch_per_change must be true or false, got '$v'"
for k in $(printf '%s\n' "$FLAT" | cut -f1 | grep '^git\.' || true); do
  in_set "${k#git.}" "integrate branch_per_change commits push" || report warning "$k" "unknown git key '${k#git.}' (known: integrate, branch_per_change, commits, push)"
done

# --- skills against catalog --------------------------------------------------------
if [ -n "$CATALOG" ]; then
  CAT=$(flatten "$CATALOG")
  cat_get() { printf '%s\n' "$CAT" | awk -F "$TAB" -v k="$1" '$1 == k { print $2; exit }'; }
  all_ids=$(printf '%s\n' "$CAT" | cut -f1 | awk -F. '$1 == "skills" && NF == 2 { print $2 }' | tr '\n' ' ')
  categories=$(printf '%s\n' "$CAT" | cut -f1 | awk -F. '$1 == "categories" && NF == 2 { print $2 }' | tr '\n' ' ')
  for key in $(printf '%s\n' "$FLAT" | cut -f1 | grep '^skills\.' || true); do
    cat_name=${key#skills.}
    if ! in_set "$cat_name" "$categories"; then
      report error "$key" "unknown catalog category '$cat_name' (known: $categories)"
      continue
    fi
    options=$(cat_get "categories.$cat_name.options" | tr ',' ' ')
    select=$(cat_get "categories.$cat_name.select")
    values=$(get "$key" | tr ',' ' ')
    count=0
    for id in $values; do
      count=$((count + 1))
      if ! in_set "$id" "$options"; then
        hint=$(closest "$id" "$options $all_ids")
        report error "$key" "unknown skill id '$id' in category '$cat_name'${hint:+, closest catalog match: $hint}"
      fi
    done
    if [ "$select" = single ] && [ "$count" -gt 1 ]; then
      report error "$key" "category '$cat_name' is single-select but lists $count skills"
    fi
  done
  wf=$(get workflow)
  if [ -n "$wf" ] && [ "$wf" != none ]; then
    wopts=$(cat_get "categories.workflow.options" | tr ',' ' ')
    in_set "$wf" "$wopts" || report error workflow "unknown workflow '$wf'$(c=$(closest "$wf" "$wopts"); [ -z "$c" ] || printf ', closest catalog match: %s' "$c")"
  fi
fi

printf 'summary%serrors=%d%swarnings=%d\n' "$TAB" "$errors" "$TAB" "$warnings"
[ "$errors" -eq 0 ]
