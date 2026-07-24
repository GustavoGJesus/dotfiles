# ============================================================
#  ~/.zshrc  —  configurado por Claude Code
#  Backup do anterior: ~/.zshrc.bak
# ============================================================

# ---- PATH ----
export PATH="$HOME/.local/bin:$PATH"
export PATH="/Users/gustavogomes/.antigravity/antigravity/bin:$PATH"           # Antigravity
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"            # Docker
export PATH="/Users/gustavogomes/.antigravity-ide/antigravity-ide/bin:$PATH"  # Antigravity IDE

# ============================================================
#  Histórico (grande, compartilhado, sem duplicados)
# ============================================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY          # compartilha entre abas em tempo real
setopt HIST_IGNORE_ALL_DUPS   # não guarda comandos duplicados
setopt HIST_IGNORE_SPACE      # comando iniciado com espaço não é salvo
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY

# ============================================================
#  Completions (case-insensitive, com menu e cores)
# ============================================================
fpath=("$HOME/dotfiles/zsh/completions" $fpath)   # completions do herdr etc.
# compinit com cache: só re-escaneia 1x por dia (mais rápido)
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
# Sugestão fantasma vinda do histórico (aperte → para aceitar)
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'   # cinza azulado (Tokyo Night)

# Realce de sintaxe — DEVE ser a última fonte da lista
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ============================================================
#  Ferramentas
# ============================================================
eval "$(starship init zsh)"   # prompt
eval "$(zoxide init zsh)"     # cd inteligente: use `z <pasta>`
source <(fzf --zsh)           # busca fuzzy: Ctrl+R hist / Ctrl+T arquivos / Alt+C cd

# fzf usando fd + cores Tokyo Night
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--height 45% --layout=reverse --border=rounded \
  --color=fg:#c0caf5,bg:-1,hl:#7aa2f7,fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff \
  --color=info:#7aa2f7,prompt:#7dcfff,pointer:#bb9af7,marker:#9ece6a,spinner:#9ece6a,header:#9ece6a"

# ============================================================
#  Aliases
# ============================================================
# ls -> eza (com ícones; precisa de Nerd Font, que você já tem)
alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --group-directories-first --git'
alias la='eza -a  --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons --group-directories-first'
alias tree='eza --tree --icons'

# cat -> bat (mantém comportamento de pipe automaticamente)
alias cat='bat --paging=never'
alias less='bat'

# atalhos úteis
alias lg='lazygit'
alias v='nvim'
alias reload='source ~/.zshrc && echo "zsh recarregado ✔"'
alias zshrc='${EDITOR:-nvim} ~/.zshrc'
alias ghosttyrc='${EDITOR:-nvim} "$HOME/Library/Application Support/com.mitchellh.ghostty/config"'

# git rápido
alias gs='git status -sb'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'

# Nota: `fd` (find moderno) e `rg` (ripgrep) ficam como comandos próprios,
# sem alias, pra não quebrar scripts que esperam o find/grep tradicionais.

export EDITOR='nvim'

# Claude Code: scroll do chat na granularidade mínima — 1 linha por evento
# de wheel (o mais próximo de "página web" que um TUI permite; a aceleração
# já está desligada via wheelScrollAccelerationEnabled=false no settings.json).
# Aceita decimais até 20 — se achar lento, suba pra 1.5 ou 2.
export CLAUDE_CODE_SCROLL_SPEED=1

# Claude Code: FORÇA mouse-tracking ligado (env tri-state: "false" = forçar
# modo full; não confundir com o antigo =1 que DESLIGAVA). Necessário com
# tui=fullscreen dentro do herdr: sem mouse ativo, o alternate-scroll do
# herdr converte a roda em setas ↑/↓ e o scroll vira navegação de histórico
# de comandos no input em vez de scrollar o chat.
export CLAUDE_CODE_DISABLE_MOUSE=false

# Herdr: se o server foi iniciado de dentro do Warp, os panes herdam o
# ambiente COMPLETO do Warp (TERM_PROGRAM=WarpTerminal + envs WARP_*).
# Efeito: o Claude Code ativa modo Warp e o plugin claude-code-warp emite
# sequências do protocolo do Warp direto no emulador do herdr, que não as
# entende → "vibração"/scroll fantasma ao mover o mouse nos panes.
# Este guard normaliza o env do pane. Regra de ouro: inicie o herdr
# SEMPRE a partir do Ghostty (nunca do Warp).
if [[ "${HERDR_ENV:-}" == "1" && "${TERM_PROGRAM:-}" == "WarpTerminal" ]]; then
  export TERM_PROGRAM=ghostty
  unset TERM_PROGRAM_VERSION
  unset -m 'WARP_*' 2>/dev/null
fi
