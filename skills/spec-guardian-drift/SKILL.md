---
name: spec-guardian-drift
description: >-
  Readonly compare .specs/ to codebase and flag drift. Blocking vs advisory;
  max 2 audits then human waive. Does not fix code or specs; does not replace
  verifier criterion mapping.
paths: .specs/**
---

# Spec guardian — drift audit

Specs in `.specs/` are the contract. Suspect drift until proven aligned.

## vs verifier
Verifier owns acceptance-criterion evidence. Guardian owns contracts/ADR/orphan consistency. Do not re-litigate every AC unless contract/ADR contradiction appears.

## Severity
- **Blocking** — holds DONE until fix or human waive
- **Advisory** — does not hold DONE alone

## Anti-loop
Max 2 rounds; Round 2 delta-only; then human.

## Read
- Relevant REQ, ARCH, ADR, contract files (+ BUG if specs changed)
- Implementation (routes, models, handlers, env vars, events)
- SHA/scope from orchestrator; Objections resolved / overrides

## Forbidden
- Chat summaries or pipeline narratives as proof of alignment; disk (`.specs/`) wins

## Checks
| Check | Drift signal | Default severity |
|-------|----------------|------------------|
| Contracts | openapi/models ≠ code | Blocking |
| ADR | Code contradicts without supersede | Blocking |
| AC with no implementation | Missing feature vs APPROVED REQ | Blocking |
| Orphan code | No REQ/ARCH traceability | Advisory (unless shipped user-facing) |
| Status hygiene | APPROVED with unresolved Blocking questions | Blocking unless deferred/override recorded |

## Report

```markdown
## Spec guardian report
**Round:** 1 | 2
### Aligned
### Blocking drift
### Advisory
### Orphan code
### done_blocked: yes | no
```

Do not edit files. End with skill `spec-handoff`.
