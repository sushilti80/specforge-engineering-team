# SpecForge — spec-driven engineering (this project)

> Specs are source of truth. Chat is ephemeral. Memory learns on disk (Principle 8).

## Paths

| Path | Purpose |
|------|---------|
| `.specs/` | REQ, ARCH, ADR, contracts, test plans (source of truth) |
| `.agents/memory/` | Durable agent memory (commit to git) |
| `SPECFORGE_HOME/` | Playbook and recipes (installed by your AI tool) |

Resolve **SPECFORGE_HOME** from the first path that exists:

- `$HOME/.cursor/` (Cursor)
- `$HOME/.codex/specforge/` (Codex)
- `$HOME/.config/opencode/specforge/` (OpenCode)
- `$HOME/.claude/docs/specforge/` (Claude Code)

Read: `SPECFORGE_HOME/ENGINEERING-PLAYBOOK.md`, `SPECFORGE_HOME/ENGINEERING-RECIPES.md`

## Start work

**Cursor:** `/spec-pipeline` or `/eng-orchestrator`

**OpenCode:** `/spec-pipeline` or `@eng-orchestrator`

**Codex / Claude:** Use this prompt template:

```
Tier: [0|1|2|3]
Recipe: [new-application | greenfield-feature | bug-fix | hotfix | maintenance | infra-change | spec-only | security-patch]

[Describe the work in 2–5 sentences]
```

Act as **eng-orchestrator** — pick tier and recipe from `ENGINEERING-RECIPES.md`, delegate with file paths only.

## Gate checkpoint (every phase)

1. Update `.specs/` if changed
2. Update `.agents/memory/_project/specs-index.md`
3. Update `.agents/memory/<agent>/MEMORY.md`
4. Optionally write `.specs/handoffs/GATE-*.md`

Fresh agent per gate. No prose paste from prior chats.

## Tiers

| Tier | Use |
|------|-----|
| 0 | Spike — no formal specs |
| 1 | MVP / small app (default) |
| 2 | Product with releases |
| 3 | Enterprise / regulated |

## Default new app

```
Tier: 1
Recipe: new-application
```

Then: requirements-analyst → challenger → architect → implementers → test-runner → verifier → spec-guardian.

## Rules

- No implementation before REQ `APPROVED` (Tier 1+)
- No architecture before REQ approved + challenger resolved
- Verifier reads REQ + code only — not implementer chat
- Never store secrets in memory files

Multi-tool guide: `SPECFORGE_HOME/MULTI-TOOL.md`
