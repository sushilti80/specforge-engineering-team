---
name: eng-orchestrator
description: Run the spec-driven orchestrator with tier and recipe
---

# Engineering orchestrator

Delegate to the `eng-orchestrator` agent with checkpoint discipline (Principle 8).

## Prompt template

```
/eng-orchestrator

Tier: [n]
Recipe: [recipe-id]

[Goal and any known REQ/ARCH/BUG paths]
```

## Examples

**New application (Tier 1):**
```
Tier: 1 | Recipe: new-application
Build a [description]. Bootstrap .specs/ if missing.
```

**Bug fix:**
```
Tier: 1 | Recipe: bug-fix
[Symptom]. Parent REQ: REQ-001 if known.
```

Read `.cursor/agent-memory/_project/specs-index.md` first if the project is bootstrapped.
