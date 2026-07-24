# ~/.zprofile — roda 1x por login shell (cada pane novo no macOS)
# Mantido enxuto: cada item aqui atrasa a abertura de TODO terminal.

eval "$(/opt/homebrew/bin/brew shellenv)"

# ============================================================
#  nvm LAZY (economiza ~500-700ms por shell)
#  O node default entra no PATH direto, sem carregar o nvm.
#  O nvm de verdade só carrega na primeira vez que você digitar `nvm`.
# ============================================================
export NVM_DIR="$HOME/.nvm"
if [ -r "$NVM_DIR/alias/default" ]; then
  _nvm_default="$(cat "$NVM_DIR/alias/default")"
  case "$_nvm_default" in v*) ;; *) _nvm_default="v$_nvm_default" ;; esac
  if [ -d "$NVM_DIR/versions/node/$_nvm_default/bin" ]; then
    export PATH="$NVM_DIR/versions/node/$_nvm_default/bin:$PATH"
  fi
  unset _nvm_default
fi
nvm() {
  unset -f nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm "$@"
}

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
