# SpecForge Engineering Team (Codex global)

> Specs are source of truth. Chat is ephemeral. Memory learns on disk (Principle 8).

## SPECFORGE_HOME

Resolve playbook and recipes from the first path that exists:

1. `$HOME/.codex/specforge/`
2. `$HOME/.config/opencode/specforge/`
3. `$HOME/.cursor/` (Cursor install)
4. `$HOME/.claude/docs/specforge/`

Files: `ENGINEERING-PLAYBOOK.md`, `ENGINEERING-RECIPES.md`, `MULTI-TOOL.md`

## Project layout (after bootstrap)

- `.specs/` — requirements, architecture, ADRs, contracts (source of truth)
- `.agents/memory/` — durable agent memory (commit to git)
- `AGENTS.md` — project-level instructions (this file is global; projects have their own)

## Start work

```
Tier: [0|1|2|3]
Recipe: [new-application | greenfield-feature | bug-fix | hotfix | maintenance | infra-change | spec-only | security-patch]

[Describe the work in 2–5 sentences]
```

Act as **eng-orchestrator**: read `SPECFORGE_HOME/ENGINEERING-RECIPES.md`, pick tier and recipe, checkpoint to `.agents/memory/` at each gate.

## Gate checkpoint (mandatory)

Before the next phase:

1. Update `.specs/` files if changed
2. Update `.agents/memory/_project/specs-index.md`
3. Update `.agents/memory/eng-orchestrator/MEMORY.md`
4. Optionally write `.specs/handoffs/GATE-*.md`

Delegate with **file paths only** (≤500 words). Do not paste prior agent prose.

## Skills

Load on demand from `$HOME/.agents/skills/`: `spec-pipeline`, `spec-recipes`, `spec-handoff`, `spec-agent-memory`, and role-specific spec-* skills.

## Default for new apps

```
Tier: 1
Recipe: new-application
```

Then run requirements-analyst → challenger → architect → implementers → test-runner → verifier → spec-guardian per recipe gates.
