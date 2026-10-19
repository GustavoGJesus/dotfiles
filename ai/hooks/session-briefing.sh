#!/usr/bin/env bash
# SessionStart hook shared by Claude Code and Codex: tells the agent where the
# work stands before the first prompt.
#
# Injects, only inside a git repo:
#   - branch, upstream drift, last commits and uncommitted files
#   - the latest handoff note, written by the handoff skill from either agent
#   - (Claude only) a nudge to consolidate MEMORY.md near its load limit
#
# Both agents send a JSON payload with `cwd` and `source` on stdin and add
# plain stdout on exit 0 to the session context. Must stay fast (<100ms) and
# must never fail the session, so every step is best effort.
# Linked to ~/.claude/hooks/session-briefing.sh and registered in
# ~/.codex/hooks.json by install.sh.

input=$(cat 2>/dev/null || true)
cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)
source_evt=$(jq -r '.source // "startup"' <<<"$input" 2>/dev/null)
cd "${cwd:-$PWD}" 2>/dev/null || exit 0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Notes are keyed by the main repo root (shared by all worktrees), slugged by
# replacing every non-alphanumeric character with "-", the same slug Claude
# Code uses for its auto memory directory.
common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
repo_root=$(dirname "$common")
slug=$(printf '%s' "$repo_root" | sed 's/[^A-Za-z0-9]/-/g')
memdir="$HOME/.claude/projects/$slug/memory"
handoff_dir="${XDG_STATE_HOME:-$HOME/.local/state}/ai-handoff"

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

# Latest handoff, if it is recent enough to still describe live work. The
# shared location wins; the old Claude-only location is read as a fallback.
handoff="$handoff_dir/$slug.md"
[ -f "$handoff" ] || handoff="$memdir/handoff.md"
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

# Claude's MEMORY.md loads only its first 200 lines / 25KB; warn before it
# truncates. Claude Code sets CLAUDE_PROJECT_DIR for its hooks, Codex does not.
index="$memdir/MEMORY.md"
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -f "$index" ]; then
  lines=$(wc -l <"$index" | tr -d ' ')
  bytes=$(wc -c <"$index" | tr -d ' ')
  if [ "$lines" -gt 170 ] || [ "$bytes" -gt 21000 ]; then
    echo
    echo "Memory hygiene: MEMORY.md is at $lines lines / $bytes bytes (loads up to 200 lines / 25KB)."
    echo "When there is a natural pause, merge overlapping entries and drop stale ones so nothing gets cut off."
  fi
fi

exit 0
