# ============================================================
#  ~/.zshrc
# ============================================================

# ---- SSH agent: keys live in the Secure Enclave via Secretive ----
export SSH_AUTH_SOCK=$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh

# ---- Node: fnm switches versions on cd (.nvmrc / .node-version) ----
eval "$(fnm env --use-on-cd --shell zsh)"

# ---- Privacy: telemetry off everywhere ----
# DO_NOT_TRACK is the cross-tool convention many CLIs honor.
export DO_NOT_TRACK=1
export HOMEBREW_NO_ANALYTICS=1        # Homebrew
export DISABLE_TELEMETRY=1            # Claude Code usage metrics
export DISABLE_ERROR_REPORTING=1      # Claude Code crash reports

# ---- New files and folders are readable by this user only ----
# The default 022 leaves everything created from a shell world-readable.
umask 077

# ---- PATH ----
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"               # Antigravity
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"  # Docker
export PATH="$HOME/.antigravity-ide/antigravity-ide/bin:$PATH"       # Antigravity IDE
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"                      # psql & co (keg-only libpq)

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
# Homebrew formulas (herdr, gh, …) ship their own completions into
# site-functions, already on fpath via `brew shellenv` in .zprofile.
# install.sh writes the completions tools generate themselves (codex) here.
fpath=("$HOME/.local/share/zsh-completions" $fpath)
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
# Claude Code ships no completion: its options are read from `claude --help`.
compdef _gnu_generic claude

# ============================================================
#  Plugins (Homebrew)
# ============================================================
# Every plugin and tool below is optional: a missing one is skipped, so a
# new shell never opens with errors before the Brewfile is installed.
has() { command -v "$1" >/dev/null 2>&1; }

# Homebrew's copy, or the one install.sh clones where Homebrew is not usable.
plugin() {
  local dir
  for dir in /opt/homebrew/share "$HOME/.local/share/zsh-plugins"; do
    [[ -r $dir/$1/$1.zsh ]] && { source "$dir/$1/$1.zsh"; return 0; }
  done
  return 1
}

# Ghost suggestion while typing (press → to accept): the last matching command
# from history, else what tab completion would offer, so `claude --dang` is
# completed to `claude --dangerously-skip-permissions` the first time too.
if plugin zsh-autosuggestions; then
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#72696a'   # warm gray (Ristretto)
fi

# Syntax highlighting — MUST be the last thing sourced
plugin zsh-syntax-highlighting

# ============================================================
#  Tools
# ============================================================
has starship && eval "$(starship init zsh)"   # prompt
has zoxide   && eval "$(zoxide init zsh)"     # smart cd: use `z <folder>`
has fzf      && source <(fzf --zsh)           # fuzzy search: Ctrl+R history / Ctrl+T files / Alt+C cd
has direnv   && eval "$(direnv hook zsh)"     # per-project env vars (.envrc), loaded automatically

# fzf powered by fd + Monokai Pro Ristretto colors
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--height 45% --layout=reverse --border=rounded \
  --color=fg:#fff1f3,bg:-1,hl:#f38d70,fg+:#fff1f3,bg+:#403838,hl+:#f9cc6c \
  --color=info:#85dacc,prompt:#f38d70,pointer:#f38d70,marker:#adda78,spinner:#f9cc6c,header:#85dacc"

# ============================================================
#  Aliases
# ============================================================
# ls -> eza (with icons; requires a Nerd Font)
if has eza; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lah --icons --group-directories-first --git'
  alias la='eza -a  --icons --group-directories-first'
  alias lt='eza --tree --level=2 --icons --group-directories-first'
  alias tree='eza --tree --icons'
fi

# cat -> bat (pipe behavior is preserved automatically)
if has bat; then
  alias cat='bat --paging=never'
  alias less='bat'
fi

# Editor: Neovim when installed, Zed otherwise
if has nvim; then
  export EDITOR='nvim'
  alias v='nvim'
elif has zed; then
  export EDITOR='zed --wait'
fi

# handy shortcuts
has lazygit && alias lg='lazygit'
alias reload='source ~/.zshrc && echo "zsh reloaded ✔"'
alias zshrc='${=EDITOR:-vi} ~/.zshrc'
alias ghosttyrc='${=EDITOR:-vi} "$HOME/Library/Application Support/com.mitchellh.ghostty/config"'

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

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
