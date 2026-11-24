---
name: orchestrator-directive
description: Autonomy directive for the main agent or any orchestrator. Load FIRST, before any orchestrated or tracked work - it decides how decisions are made - resolution ladder, reversibility rule, bd memories deep search, precedent capture, and when the human is actually needed.
---

# Orchestrator Directive

**Load this before any orchestrated work** (aidd skills, beads workflow, or
multi-agent coordination). It binds for the whole session. Everything else
(steps, tracking, identity) comes from `using-beadpowers` and
`beads-integration`.

## Opening the work session - mandatory first commands

Before touching any file, in the project where `bd` is initialised:

```bash
export BEADS_ACTOR="<tool>-<role>"   # identity, before ANY bd command
bd prime                            # memories injected in this session
bd memories dec:                    # every decision, keys first
```

`bd prime` output is part of the context: read it, do not skip it. Skipping
this step is what makes agents re-derive decisions that already exist - it is
the most common silent failure of the whole system.

## Decision ladder - how you decide

At every decision point, resolve in order. Stop at the first level that
answers:

1. **The active work**: the claimed bead, its plan, its spec, the user's
   request. Directives written there win.
2. **Precedents**: `bd memories dec:` (all decisions, one command) then
   `bd memories "<keyword>"` to narrow. An identical precedent decides; a
   neighbouring one guides by analogy - trace it (see below).
3. **Project memory**: `aidd_docs/memory/*` (or the project's equivalent).
4. **Default prudent choice** within the active directives.

Never re-ask a question a precedent already answers.

## Reversibility - the default is autonomy

Code design and implementation are yours. **Reversible work is never escalated.**

Before substantial changes: create the bead if none, take a commit checkpoint,
produce, verify (`aidd-dev:03-assert` or the project's checks), then merge or
revert to the checkpoint. Never leave a broken tree; always say which commit is
the checkpoint.

Escalate to the human only when **all** three hold:

- **Spend** (money), **irreversible** (a revert cannot undo it: deleting data,
  publishing, force-push to shared state), or **authority** (product scope,
  lifecycle), **and**
- no precedent in `bd memories` or project memory covers it, **and**
- you cannot make the action reversible or deferrable instead.

A refusal stops only the action it guards, not the rest of the request.

## Deep search over decisions (bd memories)

`bd remember` is only useful if it is findable. Two disciplines make it so:

- **Key convention**: every decision is stored as
  `bd remember "<rule>" --key dec:<domain>:<slug>` - e.g.
  `dec:vcs:commit-style`, `dec:ui:image-format`, `dec:pm:pricing`.
  `bd memories dec:` then lists every decision at once.
- **Searchable content**: first line is the rule; then scope, date, and source.
  Include the words a future agent would search (synonyms included). One
  memory per rule - storing again with the same key updates in place, it never
  accumulates.

**Lookup protocol at every decision point** (cheap, two commands):

```bash
bd memories dec:                 # all decisions, keys first
bd memories "<keyword>"          # narrow on the topic
```

Search matches isolated words and contiguous phrases only - `bd memories
"revert checkpoint"` misses "revert to checkpoint". Query one keyword at a
time, or repeat with a second keyword. `bd prime` also injects memories at
session start - do not ignore its output.

**No duplication**: a `decision`-type bead traces a one-off investigation
(spike, defect root cause); a `dec:*` memory holds the reusable rule. A
conclusion that would apply again becomes a memory; the bead stays the trail.

## Precedent capture - close the loop

**Every reversible decision you take on your own ends with a memory.** A
reusable rule that was decided today must be findable tomorrow, otherwise the
next agent pays the same discovery cost. After any judgement call that is not
already covered by an existing `dec:` memory:

```bash
bd remember "<the rule, in one line>" --key dec:<domain>:<slug> --actor "$BEADS_ACTOR"
```

Choose `<domain>` by topic (`dec:tooling:`, `dec:test:`, `dec:process:`,
`dec:ops:`), `<slug>` in kebab-case. Validate the key first: `bd memories dec:`
must list it. One memory per rule - same key updates in place.

Capture at minimum: environment gotchas that cost real time (a flag that does
not exist, a command that must be detached, a lint warning that is
pre-existing), tools the project forbids, and any rule the human or a reviewer
stated.

Every time the human answers a decision question:

```bash
bd remember "<rule as stated or implied>" --key dec:<domain>:<slug> --actor "$BEADS_ACTOR"
bd comment <active-bead-id> "decision: <X> (source: user, <date>) - memory dec:<domain>:<slug>" --actor "$BEADS_ACTOR"
```

The next identical question resolves itself at ladder level 2. If the user
answers no precedent-worthy rule, do not store noise.

## Decision tracing - visible to every agent

Any decision you take without the human leaves a trace on the active bead:

```bash
bd note <bead-id> "decided: <X> - ladder: precedent dec:...|memory|default - route: <map row or none> - checkpoint: <sha>" --actor "$BEADS_ACTOR"
```

A reviewer or another tool must be able to read *why*, not only *what*. The
`route:` field says which discipline was applied and, when the aidd skill was
not loaded, that it was deliberate.

## Routing map - the discipline is mandatory, the skill read is not

`references/routing-map.md` maps a goal to the aidd skill that owns it. It
gives the **discipline**, not a mandatory file read.

- Read the map when the goal is not obvious, and say which row applies.
- Apply the **check or artefact** the mapped skill guarantees - a written
  contract before coding, an assert loop before closing, an independent
  review before shipping. The check may come from the aidd skill, from the
  project's own tooling, or from the acceptance criteria in the bead.
- Loading the aidd `SKILL.md` is optional: it costs context and adds nothing
  when the project's own tools already enforce the same discipline.
- The map's replacement rows are **not optional**: where a bead replaces
  tickets, labels, task files or trackers, the routing row says so and the
  bead is the only truth. Never re-create a tracker on the side.

When you apply a discipline without loading the skill, record it in the trace
so the next agent does not wonder whether the skill was skipped by mistake.

Roles per skill: `../beads-integration/references/roles.md`. Refresh the map
after an aidd-framework update.
