# SpecForge Engineering Team (ForgeCode global)

> Specs are source of truth. Chat is ephemeral. Memory learns on disk (Principle 8).  
> Control plane: need → smallest recipe × tier → human APPROVED → ≤2-round anti-loops.

## SPECFORGE_HOME

Resolve playbook and recipes from the first path that exists:

1. `$HOME/.forge/specforge/`
2. `$HOME/.copilot/specforge/`
3. `$HOME/.codex/specforge/`
4. `$HOME/.config/opencode/specforge/`
5. `$HOME/.claude/docs/specforge/`
6. `$HOME/.cursor/` (Cursor install)

Files: `ENGINEERING-PLAYBOOK.md`, `ENGINEERING-RECIPES.md` **§0**, `MULTI-TOOL.md`

## Project layout (after bootstrap)

- `.specs/` — requirements, architecture, ADRs, contracts (source of truth)
- `.agents/memory/` — durable agent memory (commit to git)
- `AGENTS.md` — project-level instructions (ForgeCode walks git root → CWD and merges these)
- `.forge/agents/*.md` — SpecForge agents (project-local overrides global `~/forge/agents/`)
- `.forge/commands/` — optional `:commandname` shortcuts
- `.agents/skills/` — cross-tool skills (ForgeCode has no native skills path; load on demand)

## Start work

```
Need: [capability | bug | hotfix | greenfield product | maintenance | …]
Tier: [0|1|2|3]
Suggested recipe: [optional hint — orchestrator may reclassify]

[Describe the work in 2–5 sentences]
Stop at READY_FOR_APPROVAL — I own Status: APPROVED.
```

Switch to the orchestrator agent, then act as **eng-orchestrator**: run need checklist → pick **smallest** recipe × tier from `ENGINEERING-RECIPES.md` §0 → build **agents_planned** from matrix R only → add O only with risk reason → state skipped → checkpoint to `.agents/memory/` at each gate.

```
:agent eng-orchestrator
```

**No default production recipe.** Do not run challenger/architect/guardian/security unless matrix R or checklist flags them.

## Gate checkpoint (mandatory — manual)

ForgeCode does **not** yet support user-configurable hooks (PR #2757 was closed without merging as of 2026-07). There is no automatic checkpoint nudge. Follow this checklist manually at each gate:

1. Update `.specs/` files if changed
2. Update `.agents/memory/_project/specs-index.md`
3. Update `.agents/memory/eng-orchestrator/MEMORY.md` (**Active plan**: agents_planned / optional_added / skipped / adapt watchers)
4. Optionally write `.specs/handoffs/GATE-*.md`
5. Delegate to the next agent with **paths only** (≤500 words) — fresh session per gate

When ForgeCode ships user hooks upstream, SpecForge will add a `hooks/forge/` fragment + `bridge.py --platform forge` alias to automate this (the hook contract mirrors Claude Code: SessionStart / UserPromptSubmit / SubagentStop / PostToolUse / Stop + `additional_context` + exit 0/2).

## Skills

ForgeCode has no native skills discovery path. Skills live in `$HOME/.agents/skills/` (or `.agents/skills/` in bootstrapped projects) and are loaded **on demand** — read the relevant `SKILL.md` when a task calls for it. Available: `spec-pipeline`, `spec-recipes`, `spec-handoff`, `spec-agent-memory`, `spec-advisory`, `spec-token-budget`, and role-specific spec-* skills. Use `spec-advisory` for readonly reviews and `spec-token-budget` to cap output by profile.

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
