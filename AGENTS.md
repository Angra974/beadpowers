# Beadpowers

Beadpowers is a portable [Agent Skills](https://agentskills.io) pack for
[Beads](https://github.com/gastownhall/beads) (`bd`) workflows. The same skills work in Claude Code,
Codex CLI, OpenCode, Pi, Freebuff, Cursor, Gemini CLI, Cline, Zed, Warp and any other coding
agent that reads `AGENTS.md` or `<skills-dir>/<name>/SKILL.md`.

## Using the skills

Before any orchestrated or tracked work, load and follow:

- `skills/orchestrator-directive/SKILL.md` - the autonomy policy: decision ladder (active work ->
  `bd memories dec:` precedents -> project memory -> prudent default), reversibility rule (commit
  checkpoint, revert on failure), deep search over `bd remember`, precedent capture, decision
  tracing, and the only three cases that actually need the human.

Before any creative work - creating a feature, building a component, adding functionality or
changing behavior - load and follow:

- `skills/brainstorming/SKILL.md` - refine the idea into a validated design through short,
  one-question-at-a-time dialogue and 2-3 proposed approaches.

When the design is agreed, load and follow:

- `skills/create-beads/SKILL.md` - turn the design into a bead epic and bite-sized child tasks.

Whenever an `aidd-*` skill runs (AI-Driven Dev framework), or any agent creates, claims, closes
or reports tracked work, load and follow:

- `skills/beads-integration/SKILL.md` - overlay that routes all tracking through `bd`: agent
  identity (`<tool>-<role>`), replacement table (tickets, epics, backlog, locks), provenance and
  review handoffs.

`skills/using-beadpowers/SKILL.md` holds the routing rules (process skills first, then
implementation skills).

If your agent has a skill loader, invoke the skills by name (`brainstorming`, `create-beads`).
If it does not, read the `SKILL.md` file and follow it literally.

## Prerequisites

- The `bd` CLI must be installed (`bd version`). Install:
  `curl -fsSL https://raw.githubusercontent.com/gastownhall/beads/main/scripts/install.sh | bash`
- Each repository needs `bd init` once. It creates the `.beads/` store and an `AGENTS.md`
  section that agents can read.
- Track work with `bd create`, `bd ready`, `bd update <id> --claim`, `bd close <id>`.
- Do not write design or plan documents to `docs/plans/`; beads is the source of truth.

## Installing beadpowers

```bash
git clone https://github.com/Angra974/beadpowers.git ~/.beadpowers
~/.beadpowers/scripts/install.sh            # this user, every detected agent
~/.beadpowers/scripts/install.sh --project  # current repository, committed with it
```

Global install symlinks into `~/.agents/skills`, `~/.claude/skills`, `~/.cursor/skills`,
`~/.gemini/skills` and `~/.config/opencode/skills` when the matching agent is present.
Project install copies `.agents/skills/` and `.claude/skills/` into the repository and appends a
managed block to `AGENTS.md`, so the project is self-contained and can be committed. Use
`--symlink` for local-only project links, `--copy` for global copies, and `--uninstall` to remove
everything.

## Repository layout

```text
skills/<name>/SKILL.md    canonical Agent Skills (the source of truth)
commands/brainstorm.md    Claude Code plugin command
hooks/                    Claude Code SessionStart hook
.claude-plugin/           Claude Code plugin and marketplace manifests
scripts/install.sh        cross-agent installer
AGENTS.md                 this file (Codex, OpenCode, Pi, Freebuff, Cursor, ...)
CLAUDE.md                 imports AGENTS.md for Claude Code
```

## Working on this repository

- Skills must follow the Agent Skills spec: the `name` in frontmatter matches the directory,
  lowercase kebab-case, and the `description` says what the skill does and when to use it.
- Keep `SKILL.md` short and move detail into `references/` or `scripts/` next to it.
- Test the installer after changes: `bash -n scripts/install.sh` and
  `./scripts/install.sh --project "$(mktemp -d)"`.
- Validate the Claude Code plugin with `claude plugin validate .`.
