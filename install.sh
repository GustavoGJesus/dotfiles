#!/usr/bin/env bash
# ============================================================
#  install.sh — symlinks the dotfiles into place
#  Idempotent: run it as many times as you want.
#  Backs up any real file that already exists.
#  Usage:  ./install.sh
# ============================================================
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.dotfiles-backup/$STAMP"

# Toolchain first: install everything from the Brewfile (skipped without brew)
if command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew packages from the Brewfile…"
  brew bundle --file="$DOTFILES/Brewfile" --no-upgrade || true
  echo
fi

# Mapping:  path-in-repo | absolute-destination
PAIRS="
zsh/.zshrc|$HOME/.zshrc
zsh/.zprofile|$HOME/.zprofile
git/.gitconfig|$HOME/.gitconfig
starship/starship.toml|$HOME/.config/starship.toml
ghostty/config|$HOME/Library/Application Support/com.mitchellh.ghostty/config
lazygit/config.yml|$HOME/Library/Application Support/lazygit/config.yml
herdr/config.toml|$HOME/.config/herdr/config.toml
herdr/plugins/worktree-setup.toml|$HOME/.config/herdr/plugins/config/tdi.worktree-setup/config.toml
herdr/bin/herdr-project|$HOME/.local/bin/herdr-project
claude/themes/tokyo-night.json|$HOME/.claude/themes/tokyo-night.json
claude/themes/monokai-ristretto.json|$HOME/.claude/themes/monokai-ristretto.json
claude/statusline.sh|$HOME/.claude/statusline.sh
claude/CLAUDE.md|$HOME/.claude/CLAUDE.md
ai/AGENTS.md|$HOME/.codex/AGENTS.md
ai/hooks/session-briefing.sh|$HOME/.claude/hooks/session-briefing.sh
ai/skills/handoff|$HOME/.agents/skills/handoff
ai/codex/rules/safety.rules|$HOME/.codex/rules/safety.rules
ai/bin/codex-agents-sync|$HOME/.local/bin/codex-agents-sync
"

link() {
  local src="$DOTFILES/$1" dest="$2"
  mkdir -p "$(dirname "$dest")"

  # Already the exact link we want? Nothing to do.
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "  ✓ ok        ${dest/#$HOME/~}"
    return
  fi

  # Something real there (file or old link)? Move it to the backup.
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP$(dirname "$dest")"
    mv "$dest" "$BACKUP$dest"
    echo "  ↪ backup    ${dest/#$HOME/~}"
  fi

  ln -s "$src" "$dest"
  echo "  → linked    ${dest/#$HOME/~}"
}

echo "Installing dotfiles from: $DOTFILES"
while IFS='|' read -r src dest; do
  [ -z "$src" ] && continue
  link "$src" "$dest"
done <<< "$PAIRS"

# Herdr: plugins from herdr/plugins.txt, the Claude Code and Codex
# integrations and Herdr's own agent skill. Re-run after `brew upgrade herdr`
# so the integrations and the skill match the new version.
if command -v herdr >/dev/null 2>&1; then
  echo
  echo "Setting up Herdr…"
  installed="$(herdr plugin list 2>/dev/null || true)"
  while read -r repo; do
    case "$installed" in
      *"github:$repo@"*) echo "  ✓ plugin    $repo" ;;
      *) herdr plugin install --yes "$repo" >/dev/null && echo "  → plugin    $repo" ;;
    esac
  done < <(grep -Ev '^[[:space:]]*(#|$)' "$DOTFILES/herdr/plugins.txt")

  herdr integration install claude >/dev/null && echo "  ✓ claude    integration hooks"
  if command -v codex >/dev/null 2>&1; then
    herdr integration install codex >/dev/null && echo "  ✓ codex     integration hooks"
  fi

  # Written once under ~/.agents/skills; the mirror step below links it
  # into ~/.claude/skills for Claude Code.
  mkdir -p "$HOME/.agents/skills/herdr"
  herdr --skill >"$HOME/.agents/skills/herdr/SKILL.md" &&
    echo "  ✓ agents    skill ~/.agents/skills/herdr"
fi

# Personal skills: ~/.agents/skills is the one place they live (Codex reads
# it, and `npx skills add` installs there). Claude Code only reads
# ~/.claude/skills, so every skill is linked into it. A real folder there
# with the same content is an old copy and is replaced by the link; one that
# differs is left alone and reported.
echo
echo "Linking personal skills for Claude Code…"
for skill in "$HOME/.agents/skills"/*/; do
  skill="${skill%/}"
  name="$(basename "$skill")"
  dest="$HOME/.claude/skills/$name"
  if [ -L "$dest" ] && [ -e "$dest" ]; then
    continue
  elif [ -L "$dest" ]; then
    rm "$dest"
  elif [ -d "$dest" ]; then
    if diff -rq "$skill" "$dest" >/dev/null 2>&1 || [ "$name" = herdr ]; then
      rm -rf "$dest"
    else
      echo "  ! differs   ~/.claude/skills/$name (kept; compare with ~/.agents/skills/$name)"
      continue
    fi
  fi
  ln -s "$skill" "$dest" && echo "  → linked    ~/.claude/skills/$name"
done

# Claude Code: register the session briefing hook in settings.json once.
# settings.json stays out of the repo (it holds keys), so patch it in place.
SETTINGS="$HOME/.claude/settings.json"
BRIEFING="bash '$HOME/.claude/hooks/session-briefing.sh'"
if command -v jq >/dev/null 2>&1 && [ -f "$SETTINGS" ]; then
  if jq -e --arg c "$BRIEFING" '[.hooks.SessionStart[]?.hooks[]?.command] | index($c)' "$SETTINGS" >/dev/null; then
    echo "  ✓ claude    session briefing hook"
  else
    tmp="$(mktemp)"
    jq --arg c "$BRIEFING" '.hooks.SessionStart = ((.hooks.SessionStart // []) +
      [{"matcher": "*", "hooks": [{"type": "command", "command": $c, "timeout": 5}]}])' \
      "$SETTINGS" >"$tmp" && mv "$tmp" "$SETTINGS"
    echo "  → claude    session briefing hook registered"
  fi
fi

# Codex: the briefing hook, the MCP servers every project uses and the
# personal agents. config.toml and hooks.json stay out of the repo (Codex
# writes trust hashes and approvals into them), so they are patched in place.
if command -v codex >/dev/null 2>&1; then
  echo
  echo "Setting up Codex…"
  CODEX_HOOKS="$HOME/.codex/hooks.json"
  BRIEFING_CODEX="bash '$DOTFILES/ai/hooks/session-briefing.sh'"
  [ -f "$CODEX_HOOKS" ] || echo '{"hooks":{}}' >"$CODEX_HOOKS"
  if jq -e --arg c "$BRIEFING_CODEX" '[.hooks.SessionStart[]?.hooks[]?.command] | index($c)' "$CODEX_HOOKS" >/dev/null; then
    echo "  ✓ codex     session briefing hook"
  else
    tmp="$(mktemp)"
    jq --arg c "$BRIEFING_CODEX" '.hooks.SessionStart = ((.hooks.SessionStart // []) +
      [{"matcher": "startup|resume|clear|compact", "hooks": [{"type": "command", "command": $c, "timeout": 5}]}])' \
      "$CODEX_HOOKS" >"$tmp" && mv "$tmp" "$CODEX_HOOKS"
    echo "  → codex     session briefing hook registered (trust it once with /hooks in Codex)"
  fi

  # GitNexus registers its MCP server (Claude Code and Codex) and its skills
  # with the path `which gitnexus` returns. Inside a shell that is an
  # fnm_multishells folder that disappears later, so the fnm default alias,
  # which is stable, goes first on PATH.
  FNM_DEFAULT_BIN="$HOME/.local/share/fnm/aliases/default/bin"
  if [ -x "$FNM_DEFAULT_BIN/gitnexus" ]; then
    PATH="$FNM_DEFAULT_BIN:$PATH" gitnexus setup --coding-agent claude,codex >/dev/null 2>&1 &&
      echo "  ✓ gitnexus  mcp and skills for claude and codex"
  fi

  codex_mcp() {
    local name="$1"; shift
    if codex mcp get "$name" >/dev/null 2>&1; then
      echo "  ✓ codex     mcp $name"
    else
      codex mcp add "$name" "$@" >/dev/null && echo "  → codex     mcp $name"
    fi
  }
  # Footer and terminal title, the counterpart of claude/statusline.sh: model,
  # folder, branch, context, the 5h and weekly limits and the session cost.
  # Codex has no status line script, only built-in items, so the keys are
  # written into [tui] when missing and a local change is never overwritten.
  # The thread title in the terminal title is what Herdr's sidebar shows.
  CODEX_CONFIG="$HOME/.codex/config.toml" python3 - <<'PY'
import os, re, tomllib
path = os.environ["CODEX_CONFIG"]
text = open(path).read() if os.path.exists(path) else ""
tui = tomllib.loads(text).get("tui", {})
wanted = {
    "status_line": '["model-with-reasoning", "current-dir", "git-branch", "context-used", '
                   '"five-hour-limit", "weekly-limit", "estimated-thread-cost"]',
    "status_line_use_colors": "true",
    "terminal_title": '["spinner", "thread-title"]',
}
lines = "".join(f"{k} = {v}\n" for k, v in wanted.items() if k not in tui)
if lines:
    if re.search(r"^\[tui\]\n", text, re.M):
        text = re.sub(r"^\[tui\]\n", "[tui]\n" + lines, text, count=1, flags=re.M)
    else:
        text = text.rstrip("\n") + "\n\n[tui]\n" + lines
    open(path, "w").write(text)
    print("  → codex     status line and terminal title")
else:
    print("  ✓ codex     status line and terminal title")
PY

  command -v serena >/dev/null 2>&1 &&
    codex_mcp serena -- serena start-mcp-server --context=codex --project-from-cwd

  if [ -d "$HOME/.claude/agents" ]; then
    "$DOTFILES/ai/bin/codex-agents-sync" --src "$HOME/.claude/agents" --dest "$HOME/.codex/agents" |
      sed 's/^/  /'
    echo "  ✓ codex     agents from ~/.claude/agents"
  fi
fi

# ai-memory (akitaonrails/ai-memory): render the LaunchAgent for the native
# binary and (re)load it. The bundle itself is installed by hand from the
# GitHub release into ~/.local/share/ai-memory (see README).
AIM_BIN="$HOME/.local/share/ai-memory/ai-memory"
if [ -x "$AIM_BIN" ]; then
  AIM_PLIST="$HOME/Library/LaunchAgents/com.github.akitaonrails.ai-memory.plist"
  mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs/ai-memory"
  sed -e "s|__AI_MEMORY_BIN__|$AIM_BIN|g" -e "s|__HOME__|$HOME|g" \
    "$DOTFILES/ai-memory/launchagent.plist.template" >"$AIM_PLIST"
  launchctl bootout "gui/$(id -u)" "$AIM_PLIST" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$(id -u)" "$AIM_PLIST" && echo "  ✓ ai-memory LaunchAgent loaded"
fi

echo
if [ -d "$BACKUP" ]; then
  echo "Backups saved to: ${BACKUP/#$HOME/~}"
else
  echo "No backup needed (everything was already linked)."
fi
echo "Done ✔  Open a new terminal to apply."
