# ~/.zprofile — runs once per login shell (every new pane on macOS)
# Kept lean: every item here delays the opening of EVERY terminal.

eval "$(/opt/homebrew/bin/brew shellenv)"

# fnm is set up in .zshrc, so every interactive shell gets it, login or not.

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
