# Beadpowers

Skills for [Beads](https://github.com/gastownhall/beads) (`bd`) based workflows, usable from
Claude Code, Codex CLI, OpenCode, Pi, Freebuff, Cursor, Gemini CLI, Cline, Zed and any other
coding agent that supports [Agent Skills](https://agentskills.io) or `AGENTS.md`.

Largely inspired by [Superpowers](https://github.com/obra/superpowers), with beads-specific
modifications.

## Why?

Superpowers is great, but it generates markdown files inside `docs/plans/` without an explicit
instruction not to (and sometimes still does). With beads, work is tracked in a structured,
dependency-aware database instead. Beadpowers specializes the useful Superpowers skills for
beads: designs become epics and bite-sized tasks, not plan files.

## What you get

| Skill | Role |
| --- | --- |
| `brainstorming` | Socratic design refinement before implementation: one question at a time, 2-3 approaches, section-by-section validation. |
| `create-beads` | Converts an agreed design into a bead epic and small child tasks with files, steps and acceptance criteria. |
| `using-beadpowers` | Routing rules: process skills first, implementation skills second. |
| `orchestrator-directive` | Autonomy policy for the main agent or orchestrator: decision ladder, reversibility rule (commit checkpoint, revert on failure), deep search over `bd remember` (`dec:*` keys), precedent capture, decision tracing - the human only on spend/irreversible/authority with no precedent. |
| `beads-integration` | Overlay for the [AI-Driven Dev framework](https://github.com/ai-driven-dev/framework): agent identity (`<tool>-<role>`), replacement of tickets/labels/markdown task files by `bd`, provenance and review handoffs. See [AIDD integration](#ai-driven-dev-aidd-integration). |

Plus the Claude Code plugin command `/beadpowers:brainstorm` and a `SessionStart` hook that
injects the routing rules into Claude Code sessions.

## AI-Driven Dev (AIDD) integration

The [aidd-framework](https://github.com/ai-driven-dev/framework) ships the SDLC skills (plan,
implement, review, backlog, orchestrator agents). Beadpowers does not duplicate them: install AIDD
with its own CLI (`npx @ai-driven-dev/cli@latest setup`), then beadpowers on top. The
`beads-integration` overlay redirects every tracking decision to `bd`, so nothing is tracked twice:

| AIDD would | Beadpowers overlay does instead |
| --- | --- |
| File an issue in GitHub/Jira/Linear | `bd create` in the local beads database |
| Keep epics/tasks as backlog artifacts | `bd create --type epic` / `--parent` child tasks |
| Poll issues labeled `to-implement` | `bd ready` |
| Serialize work with `claude/working` labels | atomic `bd update --claim` leases (`bd heartbeat`, `bd reclaim`) |
| Keep task state in `aidd_docs/tasks/*.md` | the bead itself, iterations as `bd note` |

And it adds what AIDD has no equivalent for - cross-agent visibility. Every agent identifies itself
with `BEADS_ACTOR="<tool>-<role>"` (`claude-executor`, `codex-reviewer`, `pi-validator`), records
provenance for its output, and hands review through a dedicated review bead:

```bash
# executor (any tool)
bd update <task> --claim && bd provenance record --issue <task> --kind commit \
  --ref <full-sha> --ref-kind git-sha --source claude-executor && bd close <task>
REVIEW=$(bd create "Review <task>" -l review --deps blocked-by:<task> --actor claude-executor --silent)

# reviewer (a different tool or agent)
bd update <review> --claim          # shows up in bd ready once the task is closed
bd comment <task> "finding..." && bd close <review>
```

Anyone can then read `bd show`, `bd history` and `bd provenance log` to see who did what, on which
commit, and who reviewed it - whichever tool each agent ran in.

AIDD features with no tracking overlap stay untouched: project memory, refine/challenge, dev skills,
commits and PRs, telemetry.

## Compatibility

Skills follow the [Agent Skills specification](https://agentskills.io/specification), so the same
directories work everywhere. The installer writes to the locations each agent actually reads:

| Agent | Project location | Global location |
| --- | --- | --- |
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Codex CLI | `.agents/skills/` | `~/.agents/skills/` (older builds: `~/.codex/skills/`) |
| OpenCode | `.agents/skills/`, `.opencode/skills/` | `~/.config/opencode/skills/`, `~/.agents/skills/` |
| Pi | `.agents/skills/`, `.pi/skills/` | `~/.agents/skills/`, `~/.pi/agent/skills/` |
| Freebuff | `AGENTS.md`, `.agents/skills/` (as `/skill:<name>`) | `~/.AGENTS.md` (instructions only) |
| Cursor | `.agents/skills/` | `~/.cursor/skills/` |
| Gemini CLI | `.agents/skills/`, `.gemini/skills/` | `~/.gemini/skills/`, `~/.agents/skills/` |
| Cline, Zed, Warp, Amp, Droid, Kilo Code, GitHub Copilot | `.agents/skills/` | varies |
| Anything else | project `AGENTS.md` block + read `SKILL.md` | - |

`.agents/skills` is the shared, vendor-neutral location: Codex, OpenCode, Pi, Freebuff, Cursor,
Gemini CLI and many others read it natively. Claude Code uses `.claude/skills`.

## Install

### One command for every agent

Keep a clone somewhere stable (the installer symlinks into it, so updates are a `git pull`):

```bash
git clone https://github.com/pprice/beadpowers.git ~/.beadpowers
~/.beadpowers/scripts/install.sh
```

The script detects installed agents and installs the three skills globally. It is idempotent and
never overwrites a skill it did not create (use `--force` to replace one). The skills themselves
need the `bd` CLI and a `bd init` in each repository (see the Pop!_OS steps below).

To share the skills with a repository instead (committed to version control, no global config):

```bash
cd ~/code/my-project
~/.beadpowers/scripts/install.sh --project
```

Project mode vendors copies of the skills into `.agents/skills/` and `.claude/skills/` and appends
a managed block to `AGENTS.md`, so skill-less agents (Aider, Continue, Copilot, ...) are told to
read the `SKILL.md` files directly. Because they are real copies, the repository stays
self-contained: commit them and teammates get the same skills without installing anything
personally. Re-run the installer to refresh after a `git pull`.

Other options:

```bash
~/.beadpowers/scripts/install.sh --project ~/code/my-project  # explicit directory
~/.beadpowers/scripts/install.sh --project --symlink          # local links, do not commit
~/.beadpowers/scripts/install.sh --copy                       # global copies, no symlinks
~/.beadpowers/scripts/install.sh --uninstall                  # remove (add --project for a repo)
```

### Claude Code plugin

If you use Claude Code, the plugin marketplace remains the simplest install, and it also gives you
the `/beadpowers:brainstorm` command and the session hook:

```text
/plugin marketplace add pprice/beadpowers
/plugin install beadpowers@beadpowers-dev
```

Then restart `claude`. Update with `/plugin update beadpowers`. The plugin and the script can be
used together: plugin skills are namespaced (`beadpowers:brainstorming`), script skills are not.

### Manual install

```bash
git clone https://github.com/pprice/beadpowers.git ~/.beadpowers

for dir in ~/.agents/skills ~/.claude/skills ~/.cursor/skills ~/.gemini/skills ~/.config/opencode/skills; do
  mkdir -p "$dir"
  for skill in brainstorming create-beads using-beadpowers; do
    ln -sfn "$HOME/.beadpowers/skills/$skill" "$dir/$skill"
  done
done
```

Only create the directories for agents you actually use. On Windows, use a directory junction
(`mklink /J`) or `--copy`.

## Pop!_OS setup

These commands target Pop!_OS 24.04 (Ubuntu 24.04 base) and work on Debian/Ubuntu too.

### 1. Base tools

```bash
sudo apt update
sudo apt install -y git curl ca-certificates jq
```

### 2. Node.js 22 (needed by Freebuff, Codex CLI and Gemini CLI)

Pop!_OS ships an older Node.js in its repositories. The NodeSource packages are the simplest way
to get a supported version:

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node -v   # v22.x
npm -v
```

Claude Code, OpenCode and Pi have standalone installers and do not need Node.js.

### 3. Coding agents (install the ones you use)

```bash
# Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# OpenCode
curl -fsSL https://opencode.ai/v2/install | bash

# Freebuff
npm install -g freebuff

# Pi
curl -fsSL https://pi.dev/install.sh | sh

# OpenAI Codex CLI
npm install -g @openai/codex

# Gemini CLI
npm install -g @google/gemini-cli
```

Check them with `claude --version`, `opencode --version`, `freebuff --version`, `pi --version`,
`codex --version`, `gemini --version`.

### 4. Beads (`bd`)

The official installer downloads a checksum-verified release binary to `~/.local/bin`:

```bash
curl -fsSL https://raw.githubusercontent.com/gastownhall/beads/main/scripts/install.sh | bash
bd version
```

If `bd` is not found, add `~/.local/bin` to your `PATH`:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Alternatives: `npm install -g @beads/bd`, `brew install beads`, or `go install`.

Initialize beads in each repository (this also creates an `AGENTS.md` section that agents read):

```bash
cd ~/code/my-project
bd init
bd ready
```

`bd setup --list` shows optional integrations for Claude Code, Codex, Cursor and others.

### 5. Beadpowers

Run `bd init` first, then install the skills so the managed `AGENTS.md` block is appended after
beads has written its own:

```bash
git clone https://github.com/pprice/beadpowers.git ~/.beadpowers
~/.beadpowers/scripts/install.sh              # global, every detected agent
cd ~/code/my-project
~/.beadpowers/scripts/install.sh --project    # optional, committed with the repo
```

### 6. Verify

```bash
bd version
ls -l ~/.agents/skills
claude plugin validate ~/.beadpowers   # when Claude Code is installed
```

Then restart your agent and try:

| Agent | How to invoke |
| --- | --- |
| Claude Code | `/brainstorming` (or `/beadpowers:brainstorm` with the plugin) |
| OpenCode | `@brainstorming`, or ask it to use the brainstorming skill |
| Freebuff | `/skill:brainstorming` |
| Gemini CLI | `/skills list`, then ask it to use `brainstorming` |
| Codex, Pi, Cline, Zed, Cursor, ... | Ask it to "use the brainstorming skill" |

## Updating

```bash
cd ~/.beadpowers && git pull
~/.beadpowers/scripts/install.sh        # refresh global links (or --project in each repo)
```

Global symlinks follow the `git pull` automatically. Project copies (and global `--copy` installs)
must be refreshed by rerunning the installer. Claude Code plugin users can also run
`/plugin update beadpowers`.

## Uninstall

```bash
~/.beadpowers/scripts/install.sh --uninstall              # global
cd ~/code/my-project && ~/.beadpowers/scripts/install.sh --project --uninstall
```

The script removes only entries recorded in its `.beadpowers` manifests and the managed
`AGENTS.md` block. It leaves `bd`, the agents and your beads databases untouched.

## Troubleshooting

- **The skill does not appear.** Restart the agent; most index skills at startup. Check the path
  in the table above (`ls ~/.agents/skills/brainstorming/SKILL.md`).
- **A skill with the same name already exists.** The installer skips it and prints a warning.
  Rerun with `--force`, or uninstall the other pack first. Superpowers also ships a
  `brainstorming` skill; avoid installing both globally, or use project mode to pick one.
- **Symlinks are not followed (Windows, some sandboxes).** Rerun with `--copy`.
- **Codex does not list skills.** Recent Codex builds read `~/.agents/skills` natively. On older
  builds, enable the experimental feature in `~/.codex/config.toml` (`[features]` /
  `skills = true`) or run `codex --enable skills`.
- **Freebuff ignores the skills.** It reads `AGENTS.md` and `.agents/skills` from the project you
  opened. Use `--project` in that repository, or put global preferences in `~/.AGENTS.md`.
- **The agent has no skill support (older Aider, Continue, ...).** Point it at the project
  `AGENTS.md` (`aider --read AGENTS.md`, a Continue rule, or `pi --append-system-prompt AGENTS.md`),
  or paste the beadpowers block into its instructions file.
- **`bd: command not found`.** Add `~/.local/bin` to `PATH` (see above) and restart the shell.
- **Beads overwrote `AGENTS.md`.** Rerun `~/.beadpowers/scripts/install.sh --project`; the block
  is appended only once and is safe to re-add.

## Repository layout

```text
skills/<name>/SKILL.md    canonical Agent Skills (source of truth)
commands/brainstorm.md    Claude Code plugin command
hooks/                    Claude Code SessionStart hook
.claude-plugin/           Claude Code plugin and marketplace manifests
scripts/install.sh        cross-agent installer
AGENTS.md                 universal instructions (Codex, OpenCode, Pi, Freebuff, Cursor, ...)
CLAUDE.md                 imports AGENTS.md for Claude Code
```

## Credits

Inspired by [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent. Beads by Steve
Yegge and contributors. Agent Skills specification by the [agentskills.io](https://agentskills.io)
project.

## Licence

MIT License - see [LICENSE](LICENSE) for details.
