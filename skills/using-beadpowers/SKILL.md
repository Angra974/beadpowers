---
name: using-beadpowers
description: Use when starting any conversation - establishes how to find and use beadpowers skills
---

**If even 1% chance a skill applies, YOU MUST invoke it. Not negotiable.**

## Access

Skills live in `../<name>/SKILL.md`, relative to this file.

- If your agent has a skill loader, invoke the skill by name (`brainstorming`, `create-beads`).
  In Claude Code with the plugin, the names are prefixed: `beadpowers:brainstorming`.
- Otherwise, read the skill file and follow it exactly.

## The Rule

Invoke skills BEFORE any response or action. If wrong for situation, you don't need to use it.

## Red Flags (you're rationalizing)

- "Just a simple question" → Questions are tasks. Check skills.
- "Need context first" → Skill check comes BEFORE exploration.
- "I'll do this one thing first" → Check BEFORE doing anything.
- "Skill is overkill" → Simple becomes complex. Use it.

## Priority

1. **Process skills first** (brainstorming) - HOW to approach
2. **Implementation skills second** (create-beads) - guide execution

"Build X" → brainstorming first, then create-beads.

## Always-on Overlays

Two overlays apply before any step is scheduled:

- `orchestrator-directive` - load FIRST for any orchestrated or tracked work: decision ladder,
  reversibility rule, deep search over `bd remember` (`dec:*` keys), precedent capture, decision
  tracing, and what actually needs the human.
- `beads-integration` - whenever an `aidd-*` skill (AI-Driven Dev framework) runs, or whenever any
  agent creates, claims, closes or reports tracked work in a project with `bd`: it redirects
  ticket/backlog/lock/evidence work to `bd`.

## Available Skills

- `orchestrator-directive` - autonomy policy: ladder, reversibility, bd memories search, tracing
- `beads-integration` - overlay: bd identity, replacements, handoff and provenance rules
- `brainstorming` - Design refinement before implementation
- `create-beads` - Create epics/tasks from designs
