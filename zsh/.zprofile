# ~/.zprofile — runs once per login shell (every new pane on macOS)
# Kept lean: every item here delays the opening of EVERY terminal.

eval "$(/opt/homebrew/bin/brew shellenv)"

# ============================================================
#  fnm — fast Node version manager (Rust, ~10ms startup)
#  --use-on-cd: entering a project with .nvmrc/.node-version
#  switches the Node version automatically. If a version is
#  missing, run `fnm install` once inside that project.
# ============================================================
eval "$(fnm env --use-on-cd --shell zsh)"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
