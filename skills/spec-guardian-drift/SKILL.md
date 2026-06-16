---
name: spec-guardian-drift
description: >-
  Compare .specs/ to codebase and flag drift. Use after implementation or before
  marking work DONE. Readonly audit; does not fix code or specs.
paths: .specs/**
---

# Spec guardian — drift audit

Specs in `.specs/` are the contract. Suspect drift until proven aligned.

## Read
- Relevant REQ, ARCH, ADR, contract files
- Implementation (routes, models, handlers, env vars, events)

## Checks
| Check | Drift signal |
|-------|----------------|
| Acceptance criteria | Criterion with no implementation |
| Contracts | openapi.yaml / models.md ≠ code |
| ARCH | Behavior not described in spec |
| ADR | Code contradicts ADR without superseding ADR |
| Status | APPROVED spec with open questions |
| Orphan code | Feature with no REQ/ARCH traceability |

## Report

```markdown
## Spec guardian report
### Aligned
### Drift (fix spec or code)
### Orphan code (no spec traceability)
### DONE allowed: yes | no
```

Do not edit files. End with skill `spec-handoff`.
