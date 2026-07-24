#!/usr/bin/env bash
# Claude Code statusline — model · dir/branch · context · plan usage · cost
# Receives session JSON on stdin (docs: https://code.claude.com/docs/en/statusline)
# Linked to ~/.claude/statusline.sh by install.sh

input=$(cat)

# Single jq pass; "-" marks missing values (empty TSV fields would collapse)
IFS=$'\t' read -r model dir ctx five week cost added removed <<<"$(jq -r '
  [ (.model.display_name // "-"),
    (.workspace.current_dir // .cwd // "-"),
    (.context_window.used_percentage // "-"),
    (.rate_limits.five_hour.used_percentage // "-"),
    (.rate_limits.seven_day.used_percentage // "-"),
    (.cost.total_cost_usd // "-"),
    (.cost.total_lines_added // "-"),
    (.cost.total_lines_removed // "-") ] | @tsv' <<<"$input")"

# Tokyo Night
P=$'\033[38;2;187;154;247m'   # purple
C=$'\033[38;2;125;207;255m'   # cyan
B=$'\033[38;2;122;162;247m'   # blue
G=$'\033[38;2;158;206;106m'   # green
Y=$'\033[38;2;224;175;104m'   # yellow
R=$'\033[38;2;247;118;142m'   # red
D=$'\033[38;2;86;95;137m'     # dim gray-blue
X=$'\033[0m'

# green under 60%, yellow under 85%, red above
pct_color() {
  local v=${1%%.*}
  if   [ "$v" -lt 60 ] 2>/dev/null; then printf '%s' "$G"
  elif [ "$v" -lt 85 ] 2>/dev/null; then printf '%s' "$Y"
  else printf '%s' "$R"; fi
}

out="${P}✳ ${model}${X}"

if [ "$dir" != "-" ]; then
  out+="  ${C}${dir/#$HOME/\~}${X}"
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  [ -n "$branch" ] && out+=" ${B} ${branch}${X}"
fi

[ "$ctx" != "-" ]  && out+="  ${D}ctx${X} $(pct_color "$ctx")$(printf '%.0f' "$ctx")%${X}"
[ "$five" != "-" ] && out+="  ${D}5h${X} $(pct_color "$five")$(printf '%.0f' "$five")%${X}"
[ "$week" != "-" ] && out+="  ${D}7d${X} $(pct_color "$week")$(printf '%.0f' "$week")%${X}"
[ "$cost" != "-" ] && out+="  ${D}$(printf '$%.2f' "$cost")${X}"
if [ "$added" != "-" ] && { [ "$added" -gt 0 ] || [ "$removed" -gt 0 ]; } 2>/dev/null; then
  out+="  ${G}+${added}${X}${D}/${X}${R}-${removed}${X}"
fi

printf '%b' "$out"
