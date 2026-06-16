# Spec-driven application template

## One-command bootstrap

```bash
bash ~/.cursor/templates/spec-driven-app/scripts/bootstrap-project.sh /path/to/your-app
cd /path/to/your-app
```

Full plan: `~/.cursor/BOOTSTRAP-SPEC-DRIVEN-PROJECT.md`

## Manual copy

```bash
cp -R ~/.cursor/templates/spec-driven-app/.specs /path/to/your-app/
cp -R ~/.cursor/templates/spec-driven-app/.cursor /path/to/your-app/
cp -R ~/.cursor/templates/spec-driven-app/scripts /path/to/your-app/
bash /path/to/your-app/scripts/bootstrap-agent-memory.sh
```

## First Agent prompt (Tier 1 — recommended)

```
/spec-pipeline
Tier: 1 | Recipe: new-application
We are building [describe app]. Update REQ-001, then implement → test → verify.
Use Tier 1 footprint only (no full 20-agent pipeline).
```

Playbook: `~/.cursor/ENGINEERING-PLAYBOOK.md`
