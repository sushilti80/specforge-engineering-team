# SpecForge — spec-driven engineering (this project)

> Specs are source of truth. Chat is ephemeral. Memory learns on disk (Principle 8).  
> Control plane: need → smallest recipe × tier → human APPROVED → ≤2-round anti-loops.

## Paths

| Path | Purpose |
|------|---------|
| `.specs/` | REQ, ARCH, ADR, contracts, test plans, BUG, handoffs |
| `.agents/memory/` | Durable agent memory (commit to git) |
| `SPECFORGE_HOME/` | Playbook and recipes (installed by your AI tool) |

Resolve **SPECFORGE_HOME** from the first path that exists:

- `$HOME/.cursor/` (Cursor)
- `$HOME/.codex/specforge/` (Codex)
- `$HOME/.config/opencode/specforge/` (OpenCode)
- `$HOME/.claude/docs/specforge/` (Claude Code)

Read: `SPECFORGE_HOME/ENGINEERING-PLAYBOOK.md`, `SPECFORGE_HOME/ENGINEERING-RECIPES.md` **§0**

## Start work

**Cursor / OpenCode:** `/eng-orchestrator` (preferred). `/spec-pipeline` and `/spec-recipes` defer to recipes §0.

**Codex / Claude:** Use this prompt:

```
Need: [capability | bug | hotfix | greenfield product | …]
Tier: [0|1|2|3]
Suggested recipe: [optional]

[Describe the work in 2–5 sentences]
Stop at READY_FOR_APPROVAL — I own Status: APPROVED.

Act as eng-orchestrator: run need checklist, pick smallest recipe × tier,
build minimal agents_planned (state skipped), stop for user APPROVED on disk.
```

Do **not** assume `Recipe: greenfield-feature` or a full agent list.

## Gate checkpoint (every phase)

1. Update `.specs/` if changed
2. Update `.agents/memory/_project/specs-index.md`
3. Update `.agents/memory/eng-orchestrator/MEMORY.md` (**Active plan**: agents_planned / skipped / adapt watchers)
4. Optionally write `.specs/handoffs/GATE-*.md`

Fresh agent per gate. No prose paste from prior chats.

## Tiers

| Tier | Use |
|------|-----|
| 0 | Spike — no formal specs |
| 1 | MVP / small app (default) — REQ APPROVED; ARCH only if durable boundary |
| 2 | Product with releases — matrix adds architect/challenger/reviewers/guardian as R |
| 3 | Enterprise / regulated — ceiling still omit-by-checklist |

## First new app (typical Tier 1)

```
Tier: 1
Need: new product / first slice
→ new-application and/or capability (greenfield-feature)
→ REQ DRAFT → user APPROVED → implementer → test-runner → verifier
```

## Rules

- No implementation before REQ `APPROVED` when the recipe/tier requires it (user sets status)
- Agents do not self-approve REQ/ARCH
- Verifier: REQ/BUG + SHA + test report — not implementer chat
- Never store secrets in memory files

Multi-tool: `SPECFORGE_HOME/MULTI-TOOL.md` · Bootstrap: `SPECFORGE_HOME/BOOTSTRAP-SPEC-DRIVEN-PROJECT.md`
