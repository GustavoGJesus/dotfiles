# dotfiles

A beautiful, comfortable and blazing-fast terminal workspace for macOS — **Tokyo Night everywhere**.

![Herdr running Claude Code side by side with a shell — Ghostty, Tokyo Night](assets/terminal.png)

## What's inside

| Folder | File | Linked to |
|--------|------|-----------|
| `zsh/` | `.zshrc`, `.zprofile` | `~/.zshrc`, `~/.zprofile` |
| `git/` | `.gitconfig` | `~/.gitconfig` |
| `starship/` | `starship.toml` | `~/.config/starship.toml` |
| `ghostty/` | `config` | `~/Library/Application Support/com.mitchellh.ghostty/config` |
| `lazygit/` | `config.yml` | `~/Library/Application Support/lazygit/config.yml` |
| `herdr/` | `config.toml` | `~/.config/herdr/config.toml` |
| `herdr/` | `plugins/worktree-setup.toml` | `~/.config/herdr/plugins/config/tdi.worktree-setup/config.toml` |
| `herdr/` | `bin/herdr-project` | `~/.local/bin/herdr-project` |
| `herdr/` | `plugins.txt` | installed with `herdr plugin install` |
| `claude/` | `themes/tokyo-night.json`, `statusline.sh`, `CLAUDE.md` | `~/.claude/` |

## The stack

- **Terminal:** [Ghostty](https://ghostty.org) — Tokyo Night theme, FiraCode Nerd Font, frosted-glass background, global quick terminal on <kbd>⌘</kbd><kbd>`</kbd>
- **Workspace manager:** [Herdr](https://herdr.dev) — panes and workspaces built for AI coding agents, with lazygit popup, diff-review sidebar and Linear worktree shortcuts
- **Shell:** zsh + [Starship](https://starship.rs) one-line prompt + autosuggestions + syntax highlighting
- **Modern CLI:** eza · bat · fzf · zoxide · fd · ripgrep · git-delta · lazygit · neovim
- **Node toolchain:** fnm (auto-switches versions on `cd`) · ni (picks npm/pnpm/yarn from the lockfile) · direnv (per-project env vars)
- **Claude Code:** custom Tokyo Night TUI theme + finely calibrated scrolling (1 line per wheel event, no acceleration)

## Fast by design

- **fnm** — Rust-fast Node version manager: instant shell startup and automatic version switching when you `cd` into a project with `.nvmrc`
- **Cached compinit** — completions do a full re-scan at most once a day
- **One-line prompt** — no powerline, no gradients, nothing slowing you down
- **Git on autopilot** — `push.autoSetupRemote`, `pull.rebase` + `autoStash`, `rerere` (remembers conflict resolutions), pruned fetches, recency-sorted branches — plus fuzzy `gco`/`glog` helpers

## Working in Herdr

Every project lives in its own Herdr workspace with Claude Code in the root
pane. <kbd>ctrl+b</kbd> <kbd>shift+o</kbd> opens a fuzzy picker over every git
repo under `~/Documents`, ranked by how often you visit it with zoxide. Picking
one focuses its workspace if it is already open, or creates it and starts
Claude there. The sidebar shows each Claude's current task title, and a macOS
notification fires when a background agent finishes or needs you.

| Keys (after <kbd>ctrl+b</kbd>) | Action |
|------|--------|
| <kbd>shift+o</kbd> | open project with Claude (<kbd>ctrl+s</kbd> in the picker: plain shell) |
| <kbd>o</kbd> | jump to the agent that just notified you |
| <kbd>a</kbd> / <kbd>shift+a</kbd> | next / previous agent, across workspaces |
| <kbd>w</kbd> | workspace picker |
| <kbd>shift+g</kbd> | new git worktree workspace, prepared by `plugins/worktree-setup.toml` |
| <kbd>alt+l</kbd> | Linear issue → worktree + workspace |
| <kbd>alt+r</kbd> | review the agent's diff (reviewr) |
| <kbd>shift+f</kbd> | file tree and diffs |
| <kbd>alt+g</kbd> | lazygit popup |
| <kbd>?</kbd> | every binding |

`install.sh` also installs the plugins listed in `herdr/plugins.txt`, the
Claude Code integration (session resume after restarts) and Herdr's own agent
skill, so you can ask Claude to "use Herdr to run the tests in a pane beside
me". Herdr is upgraded through Homebrew; run `./install.sh` again after
`brew upgrade herdr` so the integration and the skill follow the new version.

## Install on a new machine

```bash
# 1. clone
git clone https://github.com/GustavoGJesus/dotfiles ~/dotfiles

# 2. install everything: Brewfile (tools, apps, font) + symlinks
cd ~/dotfiles && ./install.sh
```

Requires [Homebrew](https://brew.sh). The `Brewfile` declares the whole
toolchain; `install.sh` runs it automatically and then creates the symlinks.

> **Using this repo yourself?** Set your own identity in `git/.gitconfig`
> (name and email) before running `install.sh` — otherwise you'll be
> committing as me. 🙂

## How it works

`install.sh` creates **symlinks** from this repo to the place each tool expects.
The real files live here; the system just points at them. Editing anywhere =
editing the repo — then it's just a `git commit`.

Running `./install.sh` again is always safe (idempotent). Any real file found
at a destination is moved to `~/.dotfiles-backup/<timestamp>/` first.

## Updating after a change

```bash
cd ~/dotfiles
git add -A && git commit -m "tweak <file>" && git push
```
