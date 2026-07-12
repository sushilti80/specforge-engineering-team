# Spec-driven application template

## One-command bootstrap

```bash
bash scripts/bootstrap-project.sh /path/to/your-app
cd /path/to/your-app
```

Or from harness install:

```bash
bash SPECFORGE_HOME/templates/spec-driven-app/scripts/bootstrap-project.sh /path/to/your-app
```

Full plan: `SPECFORGE_HOME/BOOTSTRAP-SPEC-DRIVEN-PROJECT.md`  
Multi-tool guide: `SPECFORGE_HOME/MULTI-TOOL.md`

## First session (Tier 1 — recommended)

Need checklist → smallest recipe → **user APPROVES** specs before code. Do not invent `Status: APPROVED`.

**Cursor:**

```
/eng-orchestrator
Need: greenfield product — first slice [describe].
Tier: 1 | start Recipe: new-application then capability for first slice.
Constraints: [stack / non-goals].
Stop at READY_FOR_APPROVAL on REQ-001 (ARCH-000 only if durable boundary).
```

**OpenCode / Claude / Codex:** same intent — see project `AGENTS.md` (need → recipe × tier → human APPROVED → implement when asked).

Playbook: `SPECFORGE_HOME/ENGINEERING-PLAYBOOK.md` · Recipes: `SPECFORGE_HOME/ENGINEERING-RECIPES.md`

**Ponytail:** bootstrapped projects include `.cursor/rules/ponytail.mdc` (minimal code). Gate 3: skill `ponytail-review`.
