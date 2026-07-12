---
name: spec-handoff
description: >-
  Standard HANDOFF block and checkpoint files for spec-driven pipeline. Persist
  to .specs/handoffs/ at gate boundaries; next agent gets paths only (Principle 8).
---

# Spec handoff

Every agent phase that hands off work **must** end with this block (fill all fields):

```markdown
---
## HANDOFF
**Goal completed:** [one line]

**Artifacts written:**
- [file paths, e.g. .specs/requirements/REQ-001.md]

**Key decisions:**
- [max 5 bullets]

**For next agent — paths only (do not paste this HANDOFF block):**
- Spec files to read: [paths]
- Constraints: [hard constraints — one line each, or "see spec"]
- Open risks: [paths or IDs only — not narrative]

**Blockers:** [none | list — blocks next phase if any]

**Memory updated:**
- [.agents/memory/ paths]

**Checkpoint file:**
- [.specs/handoffs/GATE-*.md or "none"]

**Token profile:** [advisory | handoff | implement | docs-touch | release]

**Read order (next agent):** [max 3 paths — do not re-read chat]

**Do not carry forward:** [what is now only on disk]
---
```

## Principle 8 — persist before reset

1. Update specs and `specs-index.md` before the next agent runs
2. Write optional checkpoint: `.specs/handoffs/GATE-<slug>.md` (see playbook template)
3. Next agent prompt = **paths + recipe + phase** only — **never** paste this HANDOFF block, chat summaries, or tool logs

Orchestrator: delegation ≤500 words. Do not paste prior agent narratives or conversation summaries. Apply skill **`spec-token-budget`**. If parent chat contradicts disk, **disk wins**.

## Checkpoint file (orchestrator or phase owner)

Write to `.specs/handoffs/GATE-<slug>.md` at gate boundaries (recommended Tier 2+):

```markdown
# Checkpoint — [phase]
> Date: YYYY-MM-DD | Recipe: [id] | Tier: [0-3]

## Phase completed

## Spec files
- 

## Next agent / blockers

## Captured on disk (do not repeat in chat)
- 
```

## Rules

- Prefer **spec file paths** over long narrative summaries.
- Next agent reads `.specs/` as primary truth.
- If a gate is not met (e.g. REQ not APPROVED), set Blockers explicitly.
- Do not `resume` subagents across gate boundaries except same in-flight task.
