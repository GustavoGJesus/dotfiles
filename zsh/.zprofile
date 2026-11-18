# ~/.zprofile — runs once per login shell (every new pane on macOS)
# Kept lean: every item here delays the opening of EVERY terminal.

eval "$(/opt/homebrew/bin/brew shellenv)"

# fnm is set up in .zshrc, so every interactive shell gets it, login or not.
# Apps that only read the login shell's PATH (Herdr's mods, its agent
# launcher) still need the npm-installed CLIs (claude, codex): the fnm
# default alias is a stable folder for them. .zshrc's fnm env goes in front.
export PATH="$HOME/.local/share/fnm/aliases/default/bin:$PATH"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
