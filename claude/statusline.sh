#!/usr/bin/env bash
# Claude Code statusline, in groups split by a dim bar:
#   model · effort │ dir · branch │ ctx │ 5h (reset time) · 7d │ lines │ cost
# Receives session JSON on stdin (docs: https://code.claude.com/docs/en/statusline)
# Linked to ~/.claude/statusline.sh by install.sh

input=$(cat)

# Numbers arrive with a dot; a comma-decimal locale (pt_BR) would reject them.
export LC_NUMERIC=C

# Single jq pass; "-" marks missing values (empty TSV fields would collapse)
IFS=$'\t' read -r model effort dir ctx five five_reset week cost added removed <<<"$(jq -r '
  [ (.model.display_name // "-"),
    (.effort.level // "-"),
    (.workspace.current_dir // .cwd // "-"),
    (.context_window.used_percentage // "-"),
    (.rate_limits.five_hour.used_percentage // "-"),
    (.rate_limits.five_hour.resets_at // "-"),
    (.rate_limits.seven_day.used_percentage // "-"),
    (.cost.total_cost_usd // "-"),
    (.cost.total_lines_added // "-"),
    (.cost.total_lines_removed // "-") ] | @tsv' <<<"$input")"

# Monokai Pro Ristretto
P=$'\033[38;2;249;204;108m'   # gold
C=$'\033[38;2;133;218;204m'   # cyan
B=$'\033[38;2;243;141;112m'   # coral
G=$'\033[38;2;173;218;120m'   # green
Y=$'\033[38;2;249;204;108m'   # gold
R=$'\033[38;2;253;104;131m'   # red
D=$'\033[38;2;114;105;106m'   # dim warm gray
X=$'\033[0m'

# green under 60%, yellow under 85%, red above
pct() {
  local v c
  v=$(printf '%.0f' "$1")
  if   [ "$v" -lt 60 ]; then c=$G
  elif [ "$v" -lt 85 ]; then c=$Y
  else c=$R; fi
  printf '%s%s%%%s' "$c" "$v" "$X"
}

# Each group is one entry; they are joined by a dim bar at the end.
groups=()

group="${P}✳ ${model}${X}"
[ "$effort" != "-" ] && group+=" ${D}·${X} ${P}${effort}${X}"
groups+=("$group")

if [ "$dir" != "-" ]; then
  tilde="~"
  group="${C}${dir/#"$HOME"/$tilde}${X}"
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  [ -n "$branch" ] && group+=" ${D}·${X} ${B}${branch}${X}"
  groups+=("$group")
fi

[ "$ctx" != "-" ] && groups+=("${D}ctx${X} $(pct "$ctx")")

group=""
if [ "$five" != "-" ]; then
  group="${D}5h${X} $(pct "$five")"
  if [ "$five_reset" != "-" ]; then
    # BSD date (macOS) reads an epoch with -r, GNU date with -d @.
    at=$(date -r "$five_reset" +%H:%M 2>/dev/null || date -d "@$five_reset" +%H:%M 2>/dev/null)
    [ -n "$at" ] && group+=" ${D}↻${at}${X}"
  fi
fi
if [ "$week" != "-" ]; then
  [ -n "$group" ] && group+=" ${D}·${X} "
  group+="${D}7d${X} $(pct "$week")"
fi
[ -n "$group" ] && groups+=("$group")

if [ "$added" != "-" ] && { [ "$added" -gt 0 ] || [ "$removed" -gt 0 ]; } 2>/dev/null; then
  groups+=("${G}+${added}${X} ${R}−${removed}${X}")
fi

# A subscription session costs nothing: only a real amount is worth a group.
if [ "$cost" != "-" ] && [ "$(printf '%.0f' "$(echo "$cost * 100" | bc -l 2>/dev/null || echo 0)")" -gt 0 ] 2>/dev/null; then
  groups+=("${D}$(printf '$%.2f' "$cost")${X}")
fi

out=""
for group in "${groups[@]}"; do
  [ -n "$out" ] && out+=" ${D}│${X} "
  out+="$group"
done
printf '%s' "$out"
