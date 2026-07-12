---
name: eng-orchestrator
description: Run need-based orchestrator — checklist → recipe × tier → minimal agents
---

# Engineering orchestrator

Delegate to the `eng-orchestrator` agent with checkpoint discipline (Principle 8).  
Authoritative sizing: `ENGINEERING-RECIPES.md` §0. Recipe is optional — orchestrator picks from need.

## Prompt template

```
/eng-orchestrator

Need: [capability | bug | hotfix | greenfield product | …]
Tier: [n]
Suggested recipe: [optional — may reclassify]

[Goal and any known REQ/ARCH/BUG paths]
Stop at READY_FOR_APPROVAL — I own Status: APPROVED.
```

## Examples

**New application (Tier 1):**
```
Need: greenfield product — first slice
Tier: 1
Build a [description]. Bootstrap .specs/ if missing.
ARCH-000 only if durable boundary.
```

**Bug fix:**
```
Need: defect in [area]
Tier: 1
Suggested recipe: bug-fix
[Symptom]. Parent REQ: REQ-001 if known.
```

Read `.agents/memory/_project/specs-index.md` (or `.cursor/agent-memory/…`) first if the project is bootstrapped.
