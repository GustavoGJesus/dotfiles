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
claude/themes/tokyo-night.json|$HOME/.claude/themes/tokyo-night.json
claude/statusline.sh|$HOME/.claude/statusline.sh
claude/CLAUDE.md|$HOME/.claude/CLAUDE.md
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

echo
if [ -d "$BACKUP" ]; then
  echo "Backups saved to: ${BACKUP/#$HOME/~}"
else
  echo "No backup needed (everything was already linked)."
fi
echo "Done ✔  Open a new terminal to apply."
