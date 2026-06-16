---
name: spec-arch-author
description: >-
  Write ARCH specs and ADRs from APPROVED REQ files. Use for architecture design,
  alternatives, contracts, and ARCH approval in .specs/architecture/.
paths: .specs/architecture/**,.specs/decisions/**,.specs/contracts/**
---

# Spec ARCH author

Playbook: `~/.cursor/ENGINEERING-PLAYBOOK.md`

## Gate
Do not start unless linked `REQ-NNN.md` has `Status: APPROVED`.

## Deliverables
1. `.specs/architecture/ARCH-NNN-slug.md`
2. `.specs/decisions/ADR-NNN-slug.md` for each significant decision (append-only; supersede with new ADR)
3. Update `.specs/contracts/api/openapi.yaml`, `contracts/data/models.md`, `contracts/events/schema.md` when contracts change

## ARCH template

```markdown
# ARCH-NNN — [Feature Name]
> Status: DRAFT | APPROVED
> Reads: REQ-NNN | Date: YYYY-MM-DD

## Approach

## Alternatives considered
| Option | Pros | Cons | Decision |

## Component design

## API / data changes

## Failure modes

## Security surface

## Infra / ops impact

## Objections resolved
```

## ADR template

```markdown
# ADR-NNN — [Title]
> Date: YYYY-MM-DD | Status: Accepted | Supersedes: —

## Context
## Decision
## Consequences
## Alternatives rejected
```

## Rules
- ≥2 alternatives per major decision in the ARCH table.
- Do not write application code in this skill—specs only.

End with skill `spec-handoff`.
