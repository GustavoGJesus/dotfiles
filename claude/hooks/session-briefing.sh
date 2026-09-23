#!/usr/bin/env bash
# SessionStart hook: tells Claude where the work stands before the first prompt.
#
# Injects, only inside a git repo:
#   - branch, upstream drift, last commits and uncommitted files
#   - the latest handoff note (memory/handoff.md, written by the /handoff skill)
#   - a nudge to consolidate MEMORY.md when it gets close to the load limit
#
# Plain stdout on exit 0 becomes session context. Must stay fast (<100ms)
# and must never fail the session, so every step is best effort.
# Linked to ~/.claude/hooks/session-briefing.sh by install.sh

input=$(cat 2>/dev/null || true)
cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)
source_evt=$(jq -r '.source // "startup"' <<<"$input" 2>/dev/null)
cd "${cwd:-$PWD}" 2>/dev/null || exit 0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Auto memory lives under the main repo root (shared by all worktrees),
# slugged by replacing every non-alphanumeric character with "-".
common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
repo_root=$(dirname "$common")
slug=$(printf '%s' "$repo_root" | sed 's/[^A-Za-z0-9]/-/g')
memdir="$HOME/.claude/projects/$slug/memory"

branch=$(git branch --show-current 2>/dev/null)
[ -z "$branch" ] && branch="(detached at $(git rev-parse --short HEAD 2>/dev/null))"
drift=$(git rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null | awk '{
  if ($1 == 0 && $2 == 0) print "in sync with upstream";
  else printf "%s ahead, %s behind upstream", $2, $1 }')

echo "## Session briefing ($(date '+%Y-%m-%d %H:%M'), $source_evt)"
echo
echo "Branch: $branch${drift:+ ($drift)}"
echo
echo "Recent commits:"
git log -6 --format='  %h %ad %s' --date=format:'%d/%m %H:%M' 2>/dev/null

changes=$(git status --porcelain 2>/dev/null)
if [ -n "$changes" ]; then
  total=$(printf '%s\n' "$changes" | wc -l | tr -d ' ')
  echo
  echo "Uncommitted ($total):"
  printf '%s\n' "$changes" | head -12 | sed 's/^/  /'
  [ "$total" -gt 12 ] && echo "  ... and $((total - 12)) more"
fi

# Latest handoff, if it is recent enough to still describe live work.
handoff="$memdir/handoff.md"
if [ -f "$handoff" ]; then
  age_days=$(( ( $(date +%s) - $(stat -f %m "$handoff") ) / 86400 ))
  if [ "$age_days" -le 10 ]; then
    echo
    echo "## Last handoff (${age_days}d ago, $handoff)"
    echo
    head -c 6000 "$handoff"
    echo
    echo
    echo "Treat the handoff as a lead, not truth: check it against the commits above before acting on it."
  fi
fi

# MEMORY.md loads only its first 200 lines / 25KB; warn before it truncates.
index="$memdir/MEMORY.md"
if [ -f "$index" ]; then
  lines=$(wc -l <"$index" | tr -d ' ')
  bytes=$(wc -c <"$index" | tr -d ' ')
  if [ "$lines" -gt 170 ] || [ "$bytes" -gt 21000 ]; then
    echo
    echo "Memory hygiene: MEMORY.md is at $lines lines / $bytes bytes (loads up to 200 lines / 25KB)."
    echo "When there is a natural pause, merge overlapping entries and drop stale ones so nothing gets cut off."
  fi
fi

exit 0
