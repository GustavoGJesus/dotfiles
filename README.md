# dotfiles

Configuração do meu ambiente de terminal no macOS. Tudo versionado e reproduzível.

## O que tem aqui

| Pasta | Arquivo | Vai para |
|-------|---------|----------|
| `zsh/` | `.zshrc`, `.zprofile` | `~/.zshrc`, `~/.zprofile` |
| `git/` | `.gitconfig` | `~/.gitconfig` |
| `starship/` | `starship.toml` | `~/.config/starship.toml` |
| `ghostty/` | `config` | `~/Library/Application Support/com.mitchellh.ghostty/config` |
| `lazygit/` | `config.yml` | `~/Library/Application Support/lazygit/config.yml` |

## Stack

- **Terminal:** Ghostty (tema TokyoNight, JetBrainsMono Nerd Font)
- **Shell:** zsh + [starship](https://starship.rs) (prompt) + zsh-autosuggestions + zsh-syntax-highlighting
- **Ferramentas:** eza, bat, fzf, zoxide, fd, ripgrep, git-delta, lazygit, neovim

## Instalar numa máquina nova

```bash
# 1. clonar
git clone <url-do-repo> ~/dotfiles

# 2. instalar as ferramentas (Homebrew)
brew install starship zsh-autosuggestions zsh-syntax-highlighting \
  fzf eza bat zoxide git-delta fd ripgrep lazygit neovim
brew install --cask font-jetbrains-mono-nerd-font ghostty

# 3. criar os symlinks (faz backup do que já existir)
cd ~/dotfiles && ./install.sh
```

## Como funciona

O `install.sh` cria **symlinks** dos arquivos do repo para os locais originais.
Ou seja: os arquivos reais moram aqui no repo, e o sistema aponta pra eles.
Editar em qualquer lugar = editar o repo. Depois é só `git commit`.

Rodar `./install.sh` de novo é seguro (idempotente). Qualquer arquivo real
que já exista no destino é movido para `~/.dotfiles-backup/<data>/` antes.

## Atualizar o repo depois de mexer em algo

```bash
cd ~/dotfiles
git add -A && git commit -m "ajuste no <arquivo>"
```
