---
name: spec-pipeline
description: Cheat sheet entry — need checklist then defer to recipes §0 (not a full-ceiling mandate)
---

# Spec pipeline

Read skill `spec-pipeline` and `ENGINEERING-RECIPES.md` **§0**.  
This command is an **entry cheat sheet**, not a mandate to run every agent. Prefer `/eng-orchestrator` for the live run.

## Prompt template

```
Need: [capability | bug | hotfix | greenfield product | …]
Tier: [0|1|2|3]
Suggested recipe: [optional — orchestrator may reclassify]

[Describe the work in 2–5 sentences]
Stop at READY_FOR_APPROVAL — I own Status: APPROVED.
```

## Typical Tier 1 new app (not a default for all work)

```
Need: greenfield product — first slice
Tier: 1
→ new-application then capability as needed
→ REQ APPROVED by user; ARCH-000 only if durable boundary
→ implementer → test-runner → verifier
```

**No default production recipe.** Invoke `/eng-orchestrator` with the same need/tier block.
