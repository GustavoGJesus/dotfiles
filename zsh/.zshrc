# ============================================================
#  ~/.zshrc
# ============================================================

# ---- PATH ----
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"               # Antigravity
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"  # Docker
export PATH="$HOME/.antigravity-ide/antigravity-ide/bin:$PATH"       # Antigravity IDE

# ============================================================
#  History (large, shared, no duplicates)
# ============================================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY          # share across tabs in real time
setopt HIST_IGNORE_ALL_DUPS   # never store duplicated commands
setopt HIST_IGNORE_SPACE      # commands starting with a space are not saved
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY

# ============================================================
#  Completions (case-insensitive, with menu and colors)
# ============================================================
fpath=("$HOME/dotfiles/zsh/completions" $fpath)   # herdr completions etc.
# cached compinit: full re-scan at most once a day (faster startup)
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh-24) ]]; then
  compinit -C
else
  compinit
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ============================================================
#  Plugins (Homebrew)
# ============================================================
# Ghost suggestion pulled from history (press → to accept)
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'   # blue-gray (Tokyo Night)

# Syntax highlighting — MUST be the last thing sourced
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ============================================================
#  Tools
# ============================================================
eval "$(starship init zsh)"   # prompt
eval "$(zoxide init zsh)"     # smart cd: use `z <folder>`
source <(fzf --zsh)           # fuzzy search: Ctrl+R history / Ctrl+T files / Alt+C cd
eval "$(direnv hook zsh)"     # per-project env vars (.envrc), loaded automatically

# fzf powered by fd + Tokyo Night colors
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--height 45% --layout=reverse --border=rounded \
  --color=fg:#c0caf5,bg:-1,hl:#7aa2f7,fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff \
  --color=info:#7aa2f7,prompt:#7dcfff,pointer:#bb9af7,marker:#9ece6a,spinner:#9ece6a,header:#9ece6a"

# ============================================================
#  Aliases
# ============================================================
# ls -> eza (with icons; requires a Nerd Font)
alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --group-directories-first --git'
alias la='eza -a  --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons --group-directories-first'
alias tree='eza --tree --icons'

# cat -> bat (pipe behavior is preserved automatically)
alias cat='bat --paging=never'
alias less='bat'

# handy shortcuts
alias lg='lazygit'
alias v='nvim'
alias reload='source ~/.zshrc && echo "zsh reloaded ✔"'
alias zshrc='${EDITOR:-nvim} ~/.zshrc'
alias ghosttyrc='${EDITOR:-nvim} "$HOME/Library/Application Support/com.mitchellh.ghostty/config"'

# quick git
alias gs='git status -sb'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'

# gco — fuzzy branch switcher (sorted by recency, with commit preview)
gco() {
  local branch
  branch=$(git branch --sort=-committerdate --format='%(refname:short)' 2>/dev/null |
    fzf --height 50% --reverse --preview 'git log --oneline --color=always -20 {}') &&
  git checkout "$branch"
}

# glog — fuzzy commit browser (enter opens the full diff in the pager)
glog() {
  git log --color=always --format='%C(yellow)%h%Creset %s %C(blue)<%an> %C(brightblack)%cr' "$@" |
    fzf --ansi --no-sort --reverse --height 80% \
        --preview 'git show --color=always {1}' \
        --preview-window 'right:55%' \
        --bind 'enter:execute(git show --color=always {1} | less -R)'
}

# Note: `fd` (modern find) and `rg` (ripgrep) stay unaliased so scripts
# that expect the traditional find/grep keep working.

export EDITOR='nvim'

# Claude Code: chat scrolling at the finest granularity — 1 line per wheel
# event (as close to a web page as a TUI gets; acceleration is already off
# via wheelScrollAccelerationEnabled=false in settings.json).
# Accepts decimals up to 20 — bump to 1.5 or 2 if it feels slow.
export CLAUDE_CODE_SCROLL_SPEED=1

# Claude Code: FORCE mouse-tracking on (tri-state env: "false" = force full
# mode; not to be confused with =1, which DISABLES it). Required with
# tui=fullscreen inside herdr: without an active mouse, herdr's
# alternate-scroll turns the wheel into ↑/↓ arrows and scrolling becomes
# prompt-history navigation in the input instead of scrolling the chat.
export CLAUDE_CODE_DISABLE_MOUSE=false

# Herdr: if the server was started from inside Warp, panes inherit Warp's
# FULL environment (TERM_PROGRAM=WarpTerminal + WARP_* vars). Effect:
# Claude Code switches to Warp mode and the claude-code-warp plugin emits
# Warp protocol sequences straight into herdr's emulator, which doesn't
# understand them → jitter/ghost scrolling when moving the mouse over panes.
# This guard normalizes the pane env. Golden rule: ALWAYS start herdr
# from Ghostty (never from Warp).
if [[ "${HERDR_ENV:-}" == "1" && "${TERM_PROGRAM:-}" == "WarpTerminal" ]]; then
  export TERM_PROGRAM=ghostty
  unset TERM_PROGRAM_VERSION
  unset -m 'WARP_*' 2>/dev/null
fi
