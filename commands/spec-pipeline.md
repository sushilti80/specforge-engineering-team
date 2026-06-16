---
name: spec-pipeline
description: Start spec-driven work — pick tier, recipe, and first agent
---

# Spec pipeline

Read skill `spec-pipeline` and playbook `docs/ENGINEERING-PLAYBOOK.md`.

## Prompt template

```
Tier: [0|1|2|3]
Recipe: [new-application | greenfield-feature | bug-fix | hotfix | maintenance | infra-change | spec-only | security-patch]

[Describe the work in 2–5 sentences]
```

## Default for new apps (Tier 1)

```
Tier: 1
Recipe: new-application

[Your app description]
```

Invoke orchestrator: `/eng-orchestrator` with the same tier and recipe.
