# SpecForge Engineering Team (Copilot global)

> Specs are source of truth. Chat is ephemeral. Memory learns on disk (Principle 8).  
> Control plane: need → smallest recipe × tier → human APPROVED → ≤2-round anti-loops.

## SPECFORGE_HOME

Resolve playbook and recipes from the first path that exists:

1. `$HOME/.copilot/specforge/`
2. `$HOME/.codex/specforge/`
3. `$HOME/.config/opencode/specforge/`
4. `$HOME/.claude/docs/specforge/`
5. `$HOME/.cursor/` (Cursor install)

Files: `ENGINEERING-PLAYBOOK.md`, `ENGINEERING-RECIPES.md` **§0**, `MULTI-TOOL.md`

For **Copilot Cloud Agent** (no `$HOME` access), bootstrap vendors these into
`.github/` and `scripts/specforge-hooks/` — see the bootstrap section below.

## Project layout (after bootstrap)

- `.specs/` — requirements, architecture, ADRs, contracts (source of truth)
- `.agents/memory/` — durable agent memory (commit to git)
- `AGENTS.md` — project-level instructions (this file is global; projects have their own)
- `.github/agents/*.agent.md` — Copilot custom agents (cloud-safe)
- `.github/skills/` — vendored skills (cloud-safe)
- `.github/hooks/specforge.json` — Copilot hooks (relative paths to vendored scripts)
- `scripts/specforge-hooks/` — vendored `bridge.py` + core hook scripts

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

Hooks (when trusted) nudge this automatically. Still verify before the next phase:

1. Update `.specs/` files if changed
2. Update `.agents/memory/_project/specs-index.md`
3. Update `.agents/memory/eng-orchestrator/MEMORY.md` (**Active plan**: agents_planned / optional_added / skipped / adapt watchers)
4. Optionally write `.specs/handoffs/GATE-*.md`

Delegate with **file paths only** (≤500 words). Do not paste prior agent prose.

**CLI hooks** live in `~/.copilot/hooks/specforge.json` (installed by `install-copilot.sh`).
**Cloud Agent hooks** live in `.github/hooks/specforge.json` (vendored by `bootstrap-project.sh --platform copilot`) and reference `scripts/specforge-hooks/bridge.py` via relative paths. Commit `.github/` and `scripts/specforge-hooks/` so the cloud runner can execute them.

## Skills

Load on demand. CLI: `$HOME/.agents/skills/`. Cloud: `.github/skills/`.
Available: `spec-pipeline`, `spec-recipes`, `spec-handoff`, `spec-agent-memory`, and role-specific spec-* skills.

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
