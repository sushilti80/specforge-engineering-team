---
name: spec-recipes
description: >-
  Need-based workflow recipes for eng-orchestrator. Identify need first, build
  minimal plan from recipe×tier matrix, add agents only when checklist flags
  risk, adapt mid-flight. Alias capability = greenfield-feature.
disable-model-invocation: true
---

# Spec recipes

Full definitions: `SPECFORGE_HOME/ENGINEERING-RECIPES.md` (§0 + matrix).

## Rules
1. **No default production recipe** — classify need before selecting.
2. Build from **minimal + matrix R/O/—**, not from maximal ASCII pipelines.
3. **Reclassify** when evidence changes; announce before continuing.
4. HANDOFF must include: `Recipe`, `Tier`, `Need summary`, `Plan (R/O/skipped)`, `Adapt watchers`, `parent_REQ` when relevant.
5. Conflict with other docs: **recipes omit wins** unless checklist flags risk.

## Quick picker (after need checklist)

| Need | Recipe |
|------|--------|
| Spike / should we | Tier 0 note or `advisory-only` |
| Docs only | `docs-touch` |
| Vendor sync | `vendor-sync` |
| Specs only | `spec-only` |
| New product | `new-application` |
| New user-facing capability | `greenfield-feature` (`capability`) |
| Defect, normal | `bug-fix` |
| Prod-urgent | `hotfix` |
| Deps/refactor | `maintenance` |
| IaC/CI/env | `infra-change` |
| CVE / security | `security-patch` |

## Invoke

```
/eng-orchestrator — diagnose need, then minimal recipe × tier plan
```
