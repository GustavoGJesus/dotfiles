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

# Toolchain first: install everything from the Brewfile. Skipped without brew,
# and when Homebrew belongs to another account (a standard user cannot write
# to it): then the owner installs the Brewfile.
if command -v brew >/dev/null 2>&1; then
  if [ -w "$(brew --prefix)/bin" ]; then
    echo "Installing Homebrew packages from the Brewfile…"
    brew bundle --file="$DOTFILES/Brewfile" --no-upgrade || true
  else
    echo "Homebrew is not writable by $(id -un): skipping the Brewfile."
    echo "  Ask its owner to run: brew bundle --file=$DOTFILES/Brewfile"
  fi
  echo
fi

# zsh plugins: the Brewfile brings them, but not on a machine where Homebrew
# could not be used above. There they are cloned into ~/.local/share/zsh-plugins,
# the second place zsh/.zshrc looks.
ZSH_PLUGINS="$HOME/.local/share/zsh-plugins"
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  if [ -r "/opt/homebrew/share/$plugin/$plugin.zsh" ] || [ -r "$ZSH_PLUGINS/$plugin/$plugin.zsh" ]; then
    echo "  ✓ zsh       $plugin"
  elif git clone --quiet --depth 1 "https://github.com/zsh-users/$plugin.git" "$ZSH_PLUGINS/$plugin"; then
    echo "  → zsh       $plugin cloned into $ZSH_PLUGINS"
  else
    echo "  ! zsh       $plugin could not be cloned"
  fi
done

# Codex ships its own zsh completion; it is written where zsh/.zshrc adds it
# to fpath. The completion cache is dropped so the next shell picks it up.
if command -v codex >/dev/null 2>&1; then
  mkdir -p "$HOME/.local/share/zsh-completions"
  if codex completion zsh > "$HOME/.local/share/zsh-completions/_codex.new" 2>/dev/null \
     && [ -s "$HOME/.local/share/zsh-completions/_codex.new" ]; then
    if cmp -s "$HOME/.local/share/zsh-completions/_codex.new" "$HOME/.local/share/zsh-completions/_codex"; then
      rm "$HOME/.local/share/zsh-completions/_codex.new"
      echo "  ✓ zsh       codex completion"
    else
      mv "$HOME/.local/share/zsh-completions/_codex.new" "$HOME/.local/share/zsh-completions/_codex"
      rm -f "$HOME/.zcompdump"
      echo "  → zsh       codex completion"
    fi
  else
    rm -f "$HOME/.local/share/zsh-completions/_codex.new"
  fi
fi
echo

# Hardening that lives outside the linked files. npm stops running the
# install scripts of dependencies, the usual way a malicious package executes
# (a package that needs its script is built on purpose with `npm rebuild`).
# ~/.npmrc is written by npm and not linked, since it may hold tokens later.
# New documents default to the local disk instead of iCloud.
if command -v npm >/dev/null 2>&1 && [ "$(npm config get ignore-scripts)" != "true" ]; then
  npm config set ignore-scripts true && echo "  → npm       install scripts disabled"
fi
if [ "$(uname)" = Darwin ]; then
  defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
fi

# Many files point at ~/dotfiles (the CLAUDE.md import, the Brewfile hint,
# herdr). When the repo lives elsewhere, link ~/dotfiles to it.
if [ "$DOTFILES" != "$HOME/dotfiles" ] && [ ! -e "$HOME/dotfiles" ] && [ ! -L "$HOME/dotfiles" ]; then
  ln -s "$DOTFILES" "$HOME/dotfiles"
  echo "  → linked    ~/dotfiles → ${DOTFILES/#$HOME/~}"
fi

# Commit signing is per machine and stays out of the repo: git/.gitconfig
# includes ~/.gitconfig.local. Before a real ~/.gitconfig is replaced by the
# link, its signing keys are copied there unchanged. An existing
# ~/.gitconfig.local is never touched.
GITLOCAL="$HOME/.gitconfig.local"
if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ] && [ ! -e "$GITLOCAL" ]; then
  moved=""
  for key in user.signingkey commit.gpgsign gpg.format gpg.ssh.allowedSignersFile; do
    if value="$(git config --file "$HOME/.gitconfig" --get "$key")"; then
      git config --file "$GITLOCAL" "$key" "$value"
      moved="$moved $key"
    fi
  done
  [ -n "$moved" ] && echo "  → kept      ~/.gitconfig.local:$moved"
fi

# Mapping:  path-in-repo | absolute-destination
PAIRS="
zsh/.zshrc|$HOME/.zshrc
zsh/.zprofile|$HOME/.zprofile
git/.gitconfig|$HOME/.gitconfig
git/ignore|$HOME/.config/git/ignore
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
mkdir -p "$HOME/.claude/skills"
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
  # The status line, unless one is already set (a local choice is kept).
  if jq -e '.statusLine' "$SETTINGS" >/dev/null; then
    echo "  ✓ claude    status line"
  else
    tmp="$(mktemp)"
    jq --arg c "bash '$HOME/.claude/statusline.sh'" \
      '.statusLine = {"type": "command", "command": $c, "padding": 0}' \
      "$SETTINGS" >"$tmp" && mv "$tmp" "$SETTINGS"
    echo "  → claude    status line registered"
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
  # The macOS system python3 is 3.9 (no tomllib), so the [tui] keys are found
  # by scanning the section text instead of parsing the file.
  CODEX_CONFIG="$HOME/.codex/config.toml" python3 - <<'PY'
import os, re
path = os.environ["CODEX_CONFIG"]
text = open(path).read() if os.path.exists(path) else ""
section = re.search(r"^\[tui\][ \t]*(?:#.*)?\n(.*?)(?=^\[|\Z)", text, re.M | re.S)
tui = set(re.findall(r"^[ \t]*([A-Za-z0-9_-]+)[ \t]*=", section.group(1), re.M)) if section else set()
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

# vault: the drop folder that encrypts with age (see vault/vault). The script
# is copied, not linked, because the LaunchAgent that watches the folder may
# not read ~/Documents, where this repository usually lives. Re-run install.sh
# after editing vault/vault. The agent is only loaded once the keys exist;
# they are created by hand and never stored here (README, "Encrypted vault").
mkdir -p "$HOME/.local/bin"
install -m 755 "$DOTFILES/vault/vault" "$HOME/.local/bin/vault"
if [ -r "$HOME/.config/age/recipientes.txt" ]; then
  VAULT_PLIST="$HOME/Library/LaunchAgents/dev.dotfiles.vault.plist"
  mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs" "$HOME/Cofre"
  chmod 700 "$HOME/Cofre"
  sed -e "s|__HOME__|$HOME|g" "$DOTFILES/vault/launchagent.plist.template" >"$VAULT_PLIST"
  launchctl bootout "gui/$(id -u)" "$VAULT_PLIST" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$(id -u)" "$VAULT_PLIST" && echo "  ✓ vault     LaunchAgent watching ~/Cofre"
else
  echo "  ! vault     no keys in ~/.config/age yet: the drop folder is not watched"
fi

echo
if [ -d "$BACKUP" ]; then
  echo "Backups saved to: ${BACKUP/#$HOME/~}"
else
  echo "No backup needed (everything was already linked)."
fi
echo "Done ✔  Open a new terminal to apply."
