# ~/.zprofile — runs once per login shell (every new pane on macOS)
# Kept lean: every item here delays the opening of EVERY terminal.

eval "$(/opt/homebrew/bin/brew shellenv)"

# ============================================================
#  LAZY nvm (saves ~500-700ms per shell)
#  The default node goes straight into PATH without loading nvm.
#  The real nvm only loads the first time you type `nvm`.
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
