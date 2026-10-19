# AGENTS.md

These are Gustavo's macOS dotfiles. The repository is public and written
entirely in English: comments, commit messages and docs. Commit with an
imperative subject and a short prose body, then `git push`.

Every real config file on the machine is a symlink into this repository, so
always edit here, never the linked copy. `./install.sh` creates the links
(idempotent, backs up anything it replaces into `~/.dotfiles-backup/`),
installs the Brewfile, Herdr plugins and integrations, and patches the files
that cannot be versioned because a tool writes secrets or trust hashes into
them (`~/.claude/settings.json`, `~/.codex/config.toml`, `~/.codex/hooks.json`).
Add a new linked file to the `PAIRS` list in `install.sh` and to the table in
`README.md`.

## Layout

| Folder | What it holds |
|---|---|
| `ai/` | Everything shared by Claude Code and Codex: the global instructions (`AGENTS.md`), the session briefing hook, personal skills, Codex guardrails and the agent adapter generator |
| `claude/` | Claude Code only: `CLAUDE.md` (imports `ai/AGENTS.md`), themes, status line |
| `herdr/` | Herdr config, plugins list and the project launcher |
| `zsh/`, `git/`, `starship/`, `ghostty/`, `lazygit/` | Shell and terminal |
| `ai-memory/` | LaunchAgent template for the ai-memory server |

Anything that should hold for every agent goes in `ai/`, never in `claude/`.
A personal skill is a folder under `ai/skills/` linked into
`~/.agents/skills/` (Codex and `npx skills` read it), and `install.sh` links
every skill in `~/.agents/skills` into `~/.claude/skills` for Claude Code.

## Verify before committing

```bash
bash -n install.sh && ./install.sh     # idempotent; read the output
herdr config check                     # after editing herdr/config.toml
codex execpolicy check --pretty --rules ai/codex/rules/safety.rules -- <command>
```
