---
name: handoff
description: Write a session handoff so the next session in this repository, in Claude Code or Codex, picks up exactly where this one stopped. Use when the user says /handoff or $handoff, "encerrar", "passar o bastão", "salva onde paramos", "vou parar por hoje", or is about to clear or close a session with work still in flight.
---

# Handoff

Leave the next session a short, honest note about work in flight, and move
anything durable to where it belongs. The SessionStart briefing hook
(`~/dotfiles/ai/hooks/session-briefing.sh`, registered for both Claude Code
and Codex) injects this note into every new session in the repository for 10
days, next to the branch, recent commits and uncommitted files. The next
session may be a different agent than this one, so write for a reader that
shares nothing with you except the repository.

## 1. Write the note

Compute the path from the main repository root, so every worktree shares it:

```bash
root=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
note="${XDG_STATE_HOME:-$HOME/.local/state}/ai-handoff/$(printf '%s' "$root" | sed 's/[^A-Za-z0-9]/-/g').md"
mkdir -p "$(dirname "$note")" && echo "$note"
```

Overwrite that file; it describes only the current state, never a history.
Write in Brazilian Portuguese, following the writing rules in the global
instructions: prose, no em dashes linking phrases. Keep it under 60 lines,
with these sections:

```markdown
# Handoff (<YYYY-MM-DD HH:MM>, <agent that wrote it>)

## Objetivo
One or two sentences: what we were trying to achieve and why.

## Estado
What is done (with commit hashes), what is half done and in which files,
what was verified and how. Say plainly if something is broken right now.

## Próximo passo
The single next action, concrete enough to start without asking.
Then any remaining steps in order.

## Cuidado
Traps found this session: commands that must not run, flaky checks,
assumptions not yet verified, decisions still waiting on Gustavo.
```

## 2. Promote what is durable

Look back over the session for things that stay true after this task ends: a
decision with its reason, a correction from Gustavo, a non-obvious fact about
the system. Anything the repository already records (code, git history,
`AGENTS.md`, `CLAUDE.md`, `.claude/rules/`) does not belong anywhere else.

In Claude Code, save each durable fact as its own auto-memory file and add
its line to `MEMORY.md`, updating an existing memory instead of duplicating
it. Codex has no equivalent memory here, so list those facts at the end of
the note under `## Para a memória` and the next Claude session will file
them.

If the session changed how a module works in a way the next developer must
know, say so and propose the edit to the project's `AGENTS.md`, `CLAUDE.md`
or `.claude/rules/*.md` instead of burying it in a note.

## 3. Report

Tell Gustavo in two or three sentences what the note says the next step is,
where it was written, and which memories were created or updated.
