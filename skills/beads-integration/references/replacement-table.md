# Replacement table - AIDD behavior to bd commands

One row per aidd behavior that touches tracking. Run each write with
`BEADS_ACTOR` exported or `--actor`. Details: `../SKILL.md`.

## aidd-vcs

| AIDD behavior | bd replacement |
| --- | --- |
| `04-issue-create` files a bug/feature in GitHub/Jira/Linear | `bd create "Title" --type bug -d "Repro, expected behavior" -l defect` (or `--type feature`) |
| Issue labels/milestones | `bd tag <id> <label>` / `bd priority <id> P1` |
| Comment on an existing issue | `bd comment <id> "..."` |
| Link a commit/PR to the issue | `bd provenance record --issue <id> --kind commit --ref <full-40-char-sha> --ref-kind git-sha --source "$BEADS_ACTOR"` |

## aidd-pm

| AIDD behavior | bd replacement |
| --- | --- |
| `07-epic` frames an outcome-based Epic | `bd create "Epic: <outcome>" --type epic -d "Goal, criteria"` |
| `10-task` records bounded delivery work | `bd create "Task" --type task --parent <epic-id> -d "Goal, files, acceptance"` |
| `05-spike` records a decision-blocking uncertainty | `bd create "Spike: <question>" --type decision -l spike` (conclusion in `bd note`) |
| `09-defect` records a product mismatch | `bd create "Defect: <mismatch>" --type bug -l defect` |
| Spec / brief / PRD artifacts | stay files under `aidd_docs/`; link from the bead: `bd note <id> "Spec: aidd_docs/specs/..."` |
| Story slicing / ordering | children of the epic with `bd dep add <child> --blocked-by <other-child>`; order = `bd ready` |

## aidd-orchestrator

| AIDD behavior | bd replacement |
| --- | --- |
| `02-backlog` ask (read model) | `bd ready`, `bd list --all`, `bd list --parent <epic-id>`, `bd query "..."` |
| `02-backlog` intake/triage | `bd create` (+ `--deps blocked-by:` for ordering) |
| `02-backlog` lifecycle events | `bd update --claim`, `bd close`, `bd reopen`, `bd supersede` |
| `00-async-dev` polls issues labeled `to-implement` | `bd ready` |
| `00-async-dev` applies `claude/working` lock label | `bd update <id> --claim` (atomic lease; idempotent for the same actor) |
| Async pipeline checks "no open closing PR" | `bd provenance log <id>` (`land`/`commit` events) |
| Issue blocked by dependencies | `bd dep add <id> --blocked-by <other>` (blocks `bd ready`) |

## aidd-dev

| AIDD behavior | bd replacement |
| --- | --- |
| `09-for-sure` keeps task state in `aidd_docs/tasks/<task>.md` | the bead itself: status is the issue status, iterations in `bd note` |
| `01-plan` produces a phased plan | plan stays a file; the phases become child beads (`--deps blocked-by:` chains them) |
| `05-review` / `04-audit` findings | `bd comment <task-id> "finding..."`; actionable ones become fix beads `--deps discovered-from:<task-id>` |
| `10-batch` runs independent tasks | one bead per agent task, each claimed by its own actor |

## Cross-cutting

| Concern | bd command |
| --- | --- |
| Who claimed / did what | `bd show <id>` (assignee, status), `bd history <id>`, `bd provenance log <id>` |
| Agent identity | `BEADS_ACTOR="<tool>-<role>"` or `--actor` on every write |
| Long-running lease refresh | `bd heartbeat <id>` |
| Abandoning work | `bd unclaim <id>` |
| Dead worker | `bd reclaim <id>` |
