---
name: beads-integration
description: Beads overlay for AI-Driven Dev (aidd) skills and any tracked agent work. Use whenever an aidd-* skill runs, or any agent creates, claims, closes, or reports work - all task tracking, locking and handoff evidence goes through bd, never GitHub labels, markdown task files, or another tracker.
---

# Beads Integration Overlay

**When:** any `aidd-*` skill is active, or any agent creates, claims, closes or
annotates tracked work in a project that has `bd`.

## Identity - who did what

Every write to `bd` must carry an actor. At session start:

```bash
export BEADS_ACTOR="<tool>-<role>"
```

- `<tool>`: the tool running you - `claude`, `codex`, `opencode`, `pi`,
  `freebuff`, `cursor`, `copilot`, `gemini`. If unsure, ask the user once.
- `<role>`: the intervention type (full mapping in `references/roles.md`):
  `executor` writes code/docs, `reviewer` reviews finished work, `validator`
  checks acceptance criteria, `explorer` answers read-only, `planner` plans and
  specs, `pm` handles backlog intake.

Every write (`bd create`, `bd update --claim`, `bd close`, `bd comment`,
`bd provenance record`) runs as that actor - either after `export BEADS_ACTOR`
or with `--actor "$BEADS_ACTOR"`. Never let agent work be recorded under a bare
human `git user.name`.

**Export before the first `bd` command of the session, not before the first
write.** `bd` falls back to `git user.name` when no actor is set, so a claim
run without the export silently assigns the bead to the human. The symptom
appears later, at `bd close`: the close is refused because the assignee is not
you, and the only way out is `--force` - which hides the real error. If you hit
that, fix the bead's assignee (`bd update <id> --assignee "$BEADS_ACTOR"`)
rather than forcing the close.

Check the assignee on every bead you touch: it must read
`<tool>-<role>`, never a personal name.

## Replacements - do not duplicate

When an aidd skill would do the left column, do the right one instead
(full table in `references/replacement-table.md`):

| AIDD behavior | bd replacement |
| --- | --- |
| File an issue/ticket (`aidd-vcs:04-issue-create`) | `bd create "Title" --type bug\|feature\|decision -l <labels>` |
| Epic (`aidd-pm:07-epic`) | `bd create --type epic` (spec/brief stays a file, linked in a comment) |
| Task (`aidd-pm:10-task`) | `bd create --type task --parent <epic-id>` |
| Spike / Defect | `bd create --type decision -l spike` / `--type bug -l defect` |
| Backlog read (`aidd-orchestrator:02-backlog`) | `bd ready`, `bd list --all`, `bd query` |
| `to-implement` label polling | `bd ready` |
| `claude/working` lock label | `bd update <id> --claim` (lease) |
| Crashed agent, stale lease | `bd reclaim <id>` |
| Task state file (`aidd-dev:09-for-sure`) | the bead + `bd note <id>` / `bd comment <id>` |
| Done evidence | `bd provenance record ...` then `bd close <id>` |

## Intervention cycle

1. **Claim** a ready bead: `bd update <id> --claim --actor "$BEADS_ACTOR"` -
   assignee and start time are recorded, other agents see it is taken.
2. **Work**. The lease expires; refresh it during long work or before any
   pause longer than a few minutes: `bd heartbeat <id> --actor "$BEADS_ACTOR"`.
   An expired lease on an in-progress epic makes other agents think you are
   gone and invites a reclaim.
3. **Prove** before closing:
   - committed work: `bd provenance record --issue <id> --kind commit --ref <full-40-char-sha> --ref-kind git-sha --source "$BEADS_ACTOR"`
   - merged/PR: `--kind land --ref-kind pr --ref <pr-url>`
4. **Close**: `bd close <id>` with notes on what changed.

## Handoffs - one agent works, another reviews

Never self-review under the same actor. After an implementation bead closes,
wire a review bead instead of calling review inline:

```bash
REVIEW=$(bd create "Review <task-id>" --type task -l review --parent <epic-id> \
  --deps blocked-by:<task-id> --actor "$BEADS_ACTOR" --silent)
bd provenance record --issue <task-id> --kind handoff --ref "$REVIEW" \
  --ref-kind work-id --source "$BEADS_ACTOR"
```

The reviewer agent (any tool) finds it in `bd ready`, claims it, reviews the
diff, then:

- approves: `bd close <review-id>`;
- requests changes: `bd comment <task-id> "finding..."`, one fix bead per
  finding with `--deps discovered-from:<task-id>`, then `bd close <review-id>`.

Findings that need no work stay comments. Explorers never claim: they answer
through comments on the bead that asked.

## Recovery

- Work you will not finish now: `bd unclaim <id>` (back to ready, no stale lease).
- A crashed agent left a stale `in_progress` lease: `bd reclaim <id>`.
- Never force-claim another actor's live lease; only reclaim stale ones.
