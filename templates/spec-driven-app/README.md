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

## First prompt (Tier 1 — recommended)

**Cursor / OpenCode:**

```
/spec-pipeline
Tier: 1 | Recipe: new-application
We are building [describe app]. Update REQ-001, then implement → test → verify.
```

**Codex / Claude:** same tier/recipe block — see project `AGENTS.md`.

Playbook: `SPECFORGE_HOME/ENGINEERING-PLAYBOOK.md`

**Ponytail:** bootstrapped projects include `.cursor/rules/ponytail.mdc` (minimal code). Gate 3: skill `ponytail-review`.
