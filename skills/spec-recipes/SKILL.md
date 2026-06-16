---
name: spec-recipes
description: >-
  Engineering orchestrator workflow recipes: bug-fix, hotfix, maintenance,
  infra-change, greenfield-feature, new-application. Use when choosing which
  pipeline to run for production work.
disable-model-invocation: true
---

# Spec recipes

Full definitions: `~/.cursor/ENGINEERING-RECIPES.md`

## Quick picker

| Recipe | Use for |
|--------|---------|
| `greenfield-feature` | New capability (full REQ→ARCH→implement) |
| `new-application` | New product + ARCH-000 |
| `bug-fix` | Defect with BUG-NNN + parent REQ |
| `hotfix` | Urgent minimal fix + backfill |
| `maintenance` | Deps, refactor, ADR |
| `infra-change` | Terraform, CI/CD, K8s |
| `spec-only` | REQ/ARCH only, no code |
| `security-patch` | CVE / security finding |

## Invoke

```
/eng-orchestrator recipe: bug-fix — session refresh times out after 30m
/eng-orchestrator recipe: maintenance — upgrade Node 20 to 22
```

Orchestrator must print `Recipe: [id]` in every HANDOFF.
