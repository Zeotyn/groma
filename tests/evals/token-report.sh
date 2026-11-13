#!/bin/sh
# Token report of the agent evals, from `claude -p --output-format json` results.
# Read-only; never calls a model. Expects the single JSON object that
# `-p --output-format json` prints, not stream-json or the array of --verbose.
#
# Usage: token-report.sh header
#        token-report.sh row <fixture> <result.json>
#        token-report.sh text <result.json>
#        token-report.sh summary <report.tsv> [<baseline.tsv>]
#
# header   prints the report's column line.
# row      prints one report row: tokens summed over every model in `modelUsage`
#          (else the top-level `usage`), `total_cost_usd` to four decimals,
#          `num_turns`, `duration_ms` in whole seconds. A result without token
#          counts (`usage` or `modelUsage`) or without `total_cost_usd`, and a
#          missing, empty or non-JSON file, give a row of `-`; a missing
#          `num_turns` or `duration_ms` alone gives `-` in that column.
# text     prints the `result` text, unescaped (`\uXXXX` stays as is), for the
#          eval log and assertions. A JSON result without a `result` text gives
#          one line `no result text: subtype=<s> is_error=<b>`.
# summary  reads a report (and a baseline report in the same format) and prints
#          one line per fixture, then the totals. With a baseline every line adds
#          `vs_baseline` and the token and cost difference, `new` for a
#          fixture the baseline lacks, or `no baseline` when its baseline row
#          is `-`; the totals compare only fixtures present in both with a
#          result (`vs_baseline<TAB>-` when there is none). A `-` in turns or
#          duration counts as 0 in the totals.
#
# Report columns (tab-separated, first line is the header):
#   fixture input_tokens output_tokens cache_read_tokens cache_write_tokens cost_usd turns duration_s
# Summary output, tab-separated:
#   fixture<TAB><name><TAB>input=<n>...duration_s=<n>[<TAB>vs_baseline<TAB>input=<+-n>...cost_usd=<+-x>]
#   fixture<TAB><name><TAB>no result[<TAB>vs_baseline<TAB>-]
#   summary<TAB>fixtures=<n>[<TAB>no_result=<n>]<TAB>input=<n>...[<TAB>vs_baseline<TAB>...]
# Exit 0. Usage errors exit 2.
set -eu

usage() { sed -n '6,9p' "$0" | sed 's/^# //' >&2; exit 2; }

# Walks a JSON document character by character and keeps the path of keys in
# key[1..depth]; only values at known paths are used, so text inside strings
# never counts. mode=row prints a report row, mode=text the result text.
# shellcheck disable=SC2016 # awk program, expanded by awk
json_awk='
function emit(v, isstr) {
  if (depth == 1) {
    k = key[1]
    obj = 1
    if (k == "result" && isstr) text = v
    else if (k == "subtype") subtype = v
    else if (k == "is_error") is_error = v
    else if (k == "total_cost_usd") { cost = v; has_cost = 1 }
    else if (k == "num_turns") turns = v
    else if (k == "duration_ms") dur = v
  } else if (depth == 2 && key[1] == "usage") {
    seen = 1
    if (key[2] == "input_tokens") u_in = v
    else if (key[2] == "output_tokens") u_out = v
    else if (key[2] == "cache_read_input_tokens") u_cr = v
    else if (key[2] == "cache_creation_input_tokens") u_cw = v
  } else if (depth == 3 && key[1] == "modelUsage") {
    seen = 1; models = 1
    if (key[3] == "inputTokens") m_in += v
    else if (key[3] == "outputTokens") m_out += v
    else if (key[3] == "cacheReadInputTokens") m_cr += v
    else if (key[3] == "cacheCreationInputTokens") m_cw += v
  }
}
{ s = s $0 "\n" }
END {
  n = length(s); i = 1; depth = 0
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "{") { depth++; kind[depth] = "o"; want[depth] = 1; i++ }
    else if (c == "[") { depth++; kind[depth] = "a"; key[depth] = 0; i++ }
    else if (c == "}" || c == "]") { depth--; i++ }
    else if (c == ",") {
      if (kind[depth] == "o") want[depth] = 1; else key[depth]++
      i++
    }
    else if (c == "\"") {
      v = ""; i++
      while (i <= n) {
        c = substr(s, i, 1)
        if (c == "\"") { i++; break }
        if (c == "\\") {
          i++; e = substr(s, i, 1)
          if (e == "n") v = v "\n"; else if (e == "t") v = v "\t"
          else if (e == "r") v = v "\r"; else if (e == "b" || e == "f") v = v
          else if (e == "u") v = v "\\u"
          else v = v e
        } else v = v c
        i++
      }
      if (kind[depth] == "o" && want[depth]) { key[depth] = v; want[depth] = 0 }
      else emit(v, 1)
    }
    else if (c ~ /[-0-9tfn]/) {
      v = ""
      while (i <= n && substr(s, i, 1) !~ /[],} \t\r\n]/) { v = v substr(s, i, 1); i++ }
      emit(v, 0)
    }
    else i++
  }
  if (mode == "text") {
    if (text != "") print text
    else if (obj) print "no result text: subtype=" (subtype == "" ? "-" : subtype) " is_error=" (is_error == "" ? "-" : is_error)
    exit
  }
  if (!seen || !has_cost) { print fx "\t-\t-\t-\t-\t-\t-\t-"; exit }
  if (!models) { m_in = u_in; m_out = u_out; m_cr = u_cr; m_cw = u_cw }
  printf "%s\t%d\t%d\t%d\t%d\t%.4f\t%s\t%s\n", fx, m_in, m_out, m_cr, m_cw, cost,
    (turns == "" ? "-" : sprintf("%d", turns)), (dur == "" ? "-" : sprintf("%d", int(dur / 1000 + 0.5)))
}'

# shellcheck disable=SC2016 # awk program, expanded by awk
summary_awk='
BEGIN { FS = "\t"; split("input output cache_read cache_write cost_usd turns duration_s", name, " ") }
function fmt(c, x) { return x == "-" ? "-" : c == 5 ? sprintf("%.4f", x) : sprintf("%d", x) }
function sfmt(c, x) { return c == 5 ? sprintf("%+.4f", x) : sprintf("%+d", x) }
function deltas(cur, base,   c, o) {
  o = "\tvs_baseline"
  for (c = 1; c <= 5; c++) o = o "\t" name[c] "=" sfmt(c, cur[c] - base[c])
  return o
}
FILENAME == bfile {
  if ($1 == "fixture") next
  if ($2 == "-") { nobase[$1] = 1; next }
  inbase[$1] = 1; for (c = 1; c <= 7; c++) b[$1, c] = $(c + 1)
  next
}
$1 == "fixture" { next }
{
  fixtures++
  if ($2 == "-") {
    no_result++
    print "fixture\t" $1 "\tno result" (bfile != "" ? "\tvs_baseline\t-" : "")
    next
  }
  line = "fixture\t" $1
  for (c = 1; c <= 7; c++) { tot[c] += $(c + 1); line = line "\t" name[c] "=" fmt(c, $(c + 1)) }
  if (bfile != "") {
    if ($1 in inbase) {
      common++
      for (c = 1; c <= 7; c++) { cur[c] = $(c + 1); base[c] = b[$1, c]; tcur[c] += cur[c]; tbase[c] += base[c] }
      line = line deltas(cur, base)
    } else if ($1 in nobase) line = line "\tvs_baseline\tno baseline"
    else line = line "\tvs_baseline\tnew"
  }
  print line
}
END {
  line = "summary\tfixtures=" fixtures + 0
  if (no_result) line = line "\tno_result=" no_result
  for (c = 1; c <= 7; c++) line = line "\t" name[c] "=" fmt(c, tot[c])
  if (bfile != "") line = line (common ? deltas(tcur, tbase) : "\tvs_baseline\t-")
  print line
}'

[ $# -ge 1 ] || usage
case "$1" in
  header)
    printf 'fixture\tinput_tokens\toutput_tokens\tcache_read_tokens\tcache_write_tokens\tcost_usd\tturns\tduration_s\n' ;;
  row)
    [ $# -eq 3 ] || usage
    if [ -s "$3" ]; then
      awk -v mode=row -v fx="$2" "$json_awk" "$3"
    else
      printf '%s\t-\t-\t-\t-\t-\t-\t-\n' "$2"
    fi ;;
  text)
    [ $# -eq 2 ] || usage
    if [ -s "$2" ]; then awk -v mode=text "$json_awk" "$2"; fi ;;
  summary)
    [ $# -eq 2 ] || [ $# -eq 3 ] || usage
    [ -f "$2" ] || { echo "report not found: $2" >&2; exit 2; }
    if [ $# -eq 3 ]; then
      [ -f "$3" ] || { echo "baseline not found: $3" >&2; exit 2; }
      awk -v bfile="$3" "$summary_awk" "$3" "$2"
    else
      awk -v bfile="" "$summary_awk" "$2"
    fi ;;
  *) usage ;;
esac
