# Personal instructions for every coding agent

This file is the single source of Gustavo's global instructions. Codex reads
it as `~/.codex/AGENTS.md` and Claude Code imports it from
`~/.claude/CLAUDE.md`, both linked by `~/dotfiles/install.sh`. A project's own
`AGENTS.md` (or `CLAUDE.md`) adds to this and wins where they disagree.

## Language

Talk to Gustavo in Brazilian Portuguese unless he writes in another language.
Code, identifiers, comments, commit messages and repository docs follow the
project's convention, which is English in almost every repository.

## Writing style (always apply)

These rules cover everything written for Gustavo: chat replies, commit
messages, markdown and README files, page copy, PR descriptions, docs.

**No em dashes as connectors.** Never use "—" or a spaced " - " to link
phrases inside a sentence. Use a comma, a period, or rewrite the sentence.
Hyphens inside compound words are fine.

**Prose over bullets.** Write natural paragraphs by default, the way a
person would. Bullet lists are only for truly enumerable items, like a set
of commands, options or file names. If a bullet would carry a full sentence
of explanation or reasoning, turn it into prose. The same goes for tables:
only when comparing real data, never to decorate an explanation.

**Sound human.** Vary sentence length and structure. Avoid formulaic
constructions like "it's not X, it's Y" and avoid stacking short punchy
fragments. Skip filler openers such as "Great question!".

**Commit messages.** Imperative subject line plus a short prose body when
context helps. No bullet lists unless the commit genuinely bundles
independent changes.

**No AI attribution.** Commits and pull requests carry no co-author trailer
and no "Generated with" line for any agent.

## Working on this machine

Node is managed by fnm (`fnm exec --using=<version> -- <cmd>` when a project
pins a version other than the default); never install nvm. Pick npm or pnpm
from the lockfile. The machine has 8GB of RAM, so do not start Docker, a
second dev server or a full build unless the task needs it.

Both Claude Code and Codex run here, often side by side in Herdr panes on the
same repository. Assume another agent may be editing nearby: read `git status`
before committing, stage only the files you changed, and never reset, stash
or check out over changes you did not make.

Project skills live in `.agents/skills/` (the open format both agents read);
`.claude/skills/` holds links to them for Claude Code. Personal skills live in
`~/dotfiles/ai/skills/` and are linked into `~/.agents/skills` and
`~/.claude/skills`.

## Continuity between sessions

A SessionStart hook (`~/dotfiles/ai/hooks/session-briefing.sh`) injects the
branch, recent commits, uncommitted files and the latest handoff note of the
repository. When Gustavo says he is stopping ("encerrar", "vou parar por
hoje", "/handoff", "$handoff"), use the `handoff` skill so the next session,
in either agent, picks up where this one stopped.
