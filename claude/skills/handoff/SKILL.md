---
name: handoff
description: Write a session handoff so the next Claude session in this project picks up exactly where this one stopped. Use when the user says /handoff, "encerrar", "passar o bastão", "salva onde paramos", "vou parar por hoje", or is about to clear or close a session with work still in flight.
---

# Handoff

Leave the next session a short, honest note about work in flight, and move
anything durable into proper memories. The SessionStart briefing hook
(`~/.claude/hooks/session-briefing.sh`) injects this note into every new
session in the repo for 10 days, next to the branch, recent commits and
uncommitted files.

## 1. Write `handoff.md`

Path: `handoff.md` inside this project's auto-memory directory (the same
directory that holds `MEMORY.md`). Overwrite it; it describes only the
current state, never a history. Write in the language the user works in
with you (pt-BR for Gustavo), following his writing rules: prose, no em
dashes linking phrases.

Keep it under 60 lines, with these sections:

```markdown
---
name: handoff
description: Where the last session stopped (overwritten each handoff)
metadata:
  type: project
  updated: <YYYY-MM-DD HH:MM>
---

# Objetivo
One or two sentences: what we were trying to achieve and why.

# Estado
What is done (with commit hashes), what is half done and in which files,
what was verified and how. Say plainly if something is broken right now.

# Próximo passo
The single next action, concrete enough to start without asking.
Then any remaining steps in order.

# Cuidado
Traps found this session: commands that must not run, flaky checks,
assumptions not yet verified, decisions still waiting on Gustavo.
```

Do not add `handoff.md` to `MEMORY.md`; the hook delivers it.

## 2. Promote what is durable

Before finishing, look back over the session for things that stay true after
this task ends: a decision with its reason, a correction from Gustavo, a
non-obvious fact about the system, an external resource. Save each one as
its own memory file following the auto-memory format and add its line to
`MEMORY.md`, updating an existing memory instead of duplicating it. Anything
the repo already records (code, git history, CLAUDE.md, `.claude/rules/`)
does not belong in memory.

If the session changed how a module works in a way the next developer must
know, say so and propose the edit to the matching `.claude/rules/*.md` or
`CLAUDE.md` section instead of burying it in memory.

## 3. Report

Tell Gustavo in two or three sentences what the handoff says the next step
is and which memories were created or updated.
