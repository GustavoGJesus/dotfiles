#!/usr/bin/env bash
# ============================================================
#  install.sh — cria symlinks dos dotfiles pros lugares certos
#  Idempotente: pode rodar quantas vezes quiser.
#  Faz backup de qualquer arquivo real que já exista.
#  Uso:  ./install.sh
# ============================================================
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.dotfiles-backup/$STAMP"

# Mapeamento:  caminho-no-repo | destino-absoluto
PAIRS="
zsh/.zshrc|$HOME/.zshrc
zsh/.zprofile|$HOME/.zprofile
git/.gitconfig|$HOME/.gitconfig
starship/starship.toml|$HOME/.config/starship.toml
ghostty/config|$HOME/Library/Application Support/com.mitchellh.ghostty/config
lazygit/config.yml|$HOME/Library/Application Support/lazygit/config.yml
herdr/config.toml|$HOME/.config/herdr/config.toml
"

link() {
  local src="$DOTFILES/$1" dest="$2"
  mkdir -p "$(dirname "$dest")"

  # Já é exatamente o link que queremos? nada a fazer.
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "  ✓ ok        ${dest/#$HOME/~}"
    return
  fi

  # Existe algo real (arquivo ou link antigo)? move pro backup.
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP$(dirname "$dest")"
    mv "$dest" "$BACKUP$dest"
    echo "  ↪ backup    ${dest/#$HOME/~}"
  fi

  ln -s "$src" "$dest"
  echo "  → linkado   ${dest/#$HOME/~}"
}

echo "Instalando dotfiles de: $DOTFILES"
while IFS='|' read -r src dest; do
  [ -z "$src" ] && continue
  link "$src" "$dest"
done <<< "$PAIRS"

echo
if [ -d "$BACKUP" ]; then
  echo "Backups salvos em: ${BACKUP/#$HOME/~}"
else
  echo "Nenhum backup necessário (tudo já estava linkado)."
fi
echo "Pronto ✔  Abra um terminal novo para aplicar."
