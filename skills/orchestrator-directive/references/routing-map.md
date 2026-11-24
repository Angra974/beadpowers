# AIDD routing map - goal to skill

Generated from aidd-framework `docs/GUIDES.md` and `docs/CATALOG.md`. Refresh
after a framework update (regenerate from those two files). Role per skill:
`../beads-integration/references/roles.md`.

**This map is a routing table, not a script.** The row tells you the discipline
guaranteed by that skill (a contract, an assert loop, an independent review).
The discipline is mandatory; reading the aidd `SKILL.md` is not, when the
project's own tooling already enforces it. Its "replacement" rows are
mandatory in the opposite sense: a bead replaces the ticket/label/tracker
there, and the bead is the only truth. When you skip the skill read, record
why in the bead trace.

## Full delivery

| Goal | Skill |
| --- | --- |
| Deliver a request end to end (frame -> deliver -> check -> draft PR) | `aidd-orchestrator:01-sdlc` |
| Turn issues into PRs without a human | `aidd-orchestrator:00-async-dev` |
| Go step by step | the flow skills below, in order |

## Flow steps (feature)

| Step | Skill | Role |
| --- | --- | --- |
| Read the ticket | `aidd-pm:01-ticket-info` (optional) | `pm` |
| Clarify the need | `aidd-refine:01-brainstorm` (optional) | `planner` |
| Write the contract/spec | `aidd-pm:04-spec` | `planner` |
| Plan | `aidd-dev:01-plan` | `planner` |
| Implement (loop until assert passes) | `aidd-dev:02-implement` -> `aidd-dev:03-assert` | `executor` |
| Commit | `aidd-vcs:01-commit` | `executor` |
| Independent review | `aidd-dev:05-review` -> `aidd-refine:02-challenge` | `reviewer` |
| Draft pull request | `aidd-vcs:02-pull-request` | `executor` |

## Other flows

| Goal | Skills |
| --- | --- |
| Small change | `aidd-dev:01-plan` -> `02-implement` -> `03-assert` -> `05-review` |
| Fix a bug | `aidd-pm:09-defect` (if no issue) -> `aidd-dev:08-debug` -> `03-assert` -> `05-review` |
| Refactor / harden | `aidd-dev:07-refactor` -> `03-assert` -> `05-review` |
| Commit + PR + release | `aidd-vcs:01-commit` -> `02-pull-request` -> `03-release-tag` |
| Read-only codebase audit | `aidd-dev:04-audit` |
| Browser-validated dev tests | `aidd-dev:06-test` |
| Retry loop until success | `aidd-dev:09-for-sure` |
| Independent tasks in parallel | `aidd-dev:10-batch` |

## Project lifecycle

| Goal | Skill |
| --- | --- |
| Join a project / know what to do next | `aidd-context:00-onboard` |
| Start a new project | `aidd-context:01-bootstrap` |
| Write / refresh project memory | `aidd-context:02-project-memory` |
| Explore the project | `aidd-context:11-explore` |
| Capture learnings into memory/rules | `aidd-context:10-learn` |
| Generate skill / rule / agent / command / hook | `aidd-context:04` to `08-*-generate` (router: `03-context-generate`) |
| Mermaid diagram | `aidd-context:09-mermaid` |
| How-to recipes | `aidd-context:12-cook` |
| Check services reachable | `aidd-context:13-access-check` |

## Backlog and product

| Goal | Skill |
| --- | --- |
| Backlog ask / intake / refine / review | `aidd-orchestrator:02-backlog` (read model: `bd ready`, `bd list`, `bd query`) |
| User stories | `aidd-pm:02-user-stories` |
| PRD | `aidd-pm:03-prd` |
| Spike (decision-blocking uncertainty) | `aidd-pm:05-spike` (conclusion -> `bd create --type decision` + rule -> `bd remember dec:...`) |
| Product brief | `aidd-pm:06-product-brief` |
| Epic / Task / Defect | `aidd-pm:07-epic` / `10-task` / `09-defect` (tracked as beads, see replacement table) |
| Reconcile product/delivery/quality | `aidd-pm:08-three-amigos` |
| Fact-check claims | `aidd-refine:04-fact-check` |
| Blind-spot scan of an artifact | `aidd-refine:03-shadow-areas` |

## Where this map meets the directive

- Choosing the next skill is a ladder level 1/2 decision: the active bead says
  the step, precedents say the preferred flow.
- Tracking choices (beads instead of tickets/labels/files) are never decisions:
  they are the overlay rule, `../beads-integration/SKILL.md`.
- `interactive` mode of `01-sdlc` keeps its three pauses; `auto` runs the whole
  chain under this directive's escalation rules.
