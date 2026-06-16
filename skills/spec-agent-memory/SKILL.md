---
name: spec-agent-memory
description: >-
  Read and update project agent memory in .cursor/agent-memory/. Use at start
  and end of subagent work for PRD, ARCH, codebase, and recipe learnings.
paths: .cursor/agent-memory/**,.specs/**
---

# Spec agent memory

Project-scoped memory lives in **`.cursor/agent-memory/`** (commit to git for team continuity).

## At session start

1. Read `.cursor/agent-memory/_project/MEMORY.md` (shared context).
2. Read `.cursor/agent-memory/_project/specs-index.md` (REQ/ARCH/BUG status).
3. If you know your agent role (e.g. `backend-engineer`), read `.cursor/agent-memory/<agent-name>/MEMORY.md`.

## What to record

- PRD/REQ features and implementation status
- Architecture decisions and component relationships (link ARCH/ADR paths)
- Codebase patterns, module locations, conventions
- Test patterns and common failure modes
- Phase/feature dependencies
- Useful technology notes from research (with links)
- Config and environment variable dependencies
- Blockers and known issues
- **Recipe** used (`bug-fix`, `maintenance`, etc.) and outcome

## File layout

| Path | Purpose |
|------|---------|
| `_project/MEMORY.md` | Shared — stack, conventions, links (keep ≤200 lines) |
| `_project/specs-index.md` | Table of REQ/ARCH/BUG status |
| `<agent-name>/MEMORY.md` | Role-specific durable notes |
| `<agent-name>/<topic>.md` | Deep dives; link from MEMORY.md |

## Guidelines

- Keep **`MEMORY.md` concise** — aim under **200 lines** (long files dilute attention).
- Use **topic files** (`debugging.md`, `patterns.md`, `infra.md`) for detail; link from MEMORY.md.
- Update or **delete** outdated memories.
- Organize by **topic**, not chronology.
- **Never store secrets**, tokens, or credentials.
- Prefer **paths and facts** over narrative; specs in `.specs/` remain source of truth — memory is an index, not a replacement.

## Learning journal (plugin hooks)

Plugin hooks append to `_project/learning-journal.md` on spec/memory edits. **Distill** durable entries into `MEMORY.md`; delete noise from the journal periodically.

## At session end

1. Update your agent `MEMORY.md` with new learnings.
2. Update `_project/specs-index.md` if spec status changed.
3. If a lesson applies to all agents, add one line to `_project/MEMORY.md`.
4. At **gate boundaries**, orchestrator writes checkpoint to `.specs/handoffs/`; do not rely on chat for next phase (Principle 8).

## HANDOFF addition

Add to HANDOFF when relevant:

```markdown
**Memory updated:**
- `.cursor/agent-memory/<agent>/MEMORY.md`
- [other files]
```
