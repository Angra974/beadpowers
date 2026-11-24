# Roles and tool identity

`BEADS_ACTOR="<tool>-<role>"` - both halves matter: the tool says which agent
ran, the role says what kind of intervention it was. Another agent reading
`bd show <id>` must be able to answer "who did this and in what capacity".

## Role mapping

| aidd skill / agent | role |
| --- | --- |
| `aidd-orchestrator` agent `executor`; `aidd-dev:02-implement`, `06-test`, `07-refactor`, `08-debug`, `09-for-sure`, `10-batch` | `executor` |
| `aidd-orchestrator` agent `reviewer`; `aidd-dev:04-audit`, `05-review`; `aidd-refine:02-challenge`, `03-shadow-areas`, `05-review-conversation` | `reviewer` |
| `aidd-orchestrator` agent `validator`; `aidd-dev:03-assert`; `aidd-refine:04-fact-check` | `validator` |
| `aidd-orchestrator` agent `explorer`; `aidd-context:11-explore` | `explorer` |
| `aidd-dev:01-plan`; `aidd-refine:01-brainstorm`; `aidd-context:01-bootstrap` | `planner` |
| `aidd-pm:*`; `aidd-orchestrator:02-backlog`; `aidd-vcs:04-issue-create` | `pm` |
| `aidd-context:*` (memory, generators); `aidd-vcs:*` (commit, PR, tags) | `executor` |
| `aidd-ui:*` | `executor` |
| `aidd-qa:*` | `validator` |
| `aidd-telemetry:*` | no bd writes (measurement only) |

Skills outside aidd (plain `create-beads`, one-off tracked work): use the role
that matches what you are doing - usually `executor` for changes, `reviewer`
for reviews.

## Tool detection

Use the name of the tool you are running in - every agent knows its own name.
Environment hints, useful when automating:

| Tool | Hint |
| --- | --- |
| Claude Code | `CLAUDECODE=1`, `CLAUDE_CODE_ENTRYPOINT` |
| Cursor | `CURSOR_TRACE_ID` |
| Cline | `CLINE_*` variables |

No hint matches and you cannot tell: ask the user once, then keep the answer
for the session. Unknown tool beats wrong tool - `agent-<role>` is better than
a bare human name.
