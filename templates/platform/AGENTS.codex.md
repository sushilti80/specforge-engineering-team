# SpecForge Engineering Team (Codex global)

> Specs are source of truth. Chat is ephemeral. Memory learns on disk (Principle 8).  
> Control plane: need → smallest recipe × tier → human APPROVED → ≤2-round anti-loops.

## SPECFORGE_HOME

Resolve playbook and recipes from the first path that exists:

1. `$HOME/.codex/specforge/`
2. `$HOME/.config/opencode/specforge/`
3. `$HOME/.cursor/` (Cursor install)
4. `$HOME/.claude/docs/specforge/`

Files: `ENGINEERING-PLAYBOOK.md`, `ENGINEERING-RECIPES.md` **§0**, `MULTI-TOOL.md`

## Project layout (after bootstrap)

- `.specs/` — requirements, architecture, ADRs, contracts (source of truth)
- `.agents/memory/` — durable agent memory (commit to git)
- `AGENTS.md` — project-level instructions (this file is global; projects have their own)

## Start work

```
Need: [capability | bug | hotfix | greenfield product | maintenance | …]
Tier: [0|1|2|3]
Suggested recipe: [optional hint — orchestrator may reclassify]

[Describe the work in 2–5 sentences]
Stop at READY_FOR_APPROVAL — I own Status: APPROVED.
```

Act as **eng-orchestrator**: run need checklist → pick **smallest** recipe × tier from `ENGINEERING-RECIPES.md` §0 → build **agents_planned** from matrix R only → add O only with risk reason → state skipped → checkpoint to `.agents/memory/` at each gate.

**No default production recipe.** Do not run challenger/architect/guardian/security unless matrix R or checklist flags them.

## Gate checkpoint (mandatory)

Before the next phase:

1. Update `.specs/` files if changed
2. Update `.agents/memory/_project/specs-index.md`
3. Update `.agents/memory/eng-orchestrator/MEMORY.md` (**Active plan**: agents_planned / optional_added / skipped / adapt watchers)
4. Optionally write `.specs/handoffs/GATE-*.md`

Delegate with **file paths only** (≤500 words). Do not paste prior agent prose.

## Skills

Load on demand from `$HOME/.agents/skills/`: `spec-pipeline`, `spec-recipes`, `spec-handoff`, `spec-agent-memory`, and role-specific spec-* skills.

## First new app (typical Tier 1)

```
Need: greenfield product — first slice
Tier: 1
→ new-application and/or capability (greenfield-feature)
→ REQ-001 DRAFT → user APPROVED
→ ARCH-000 only if durable boundary (API/schema/auth/deploy)
→ then implementer → test-runner → verifier
```

Do **not** assume full chain (challenger → architect → guardian) at Tier 1.
