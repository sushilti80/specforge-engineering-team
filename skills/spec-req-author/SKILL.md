---
name: spec-req-author
description: >-
  Write or update REQ specs in .specs/requirements/. Creates DRAFT REQs and
  resolves challenger objections. User sets Status: APPROVED — agents must not.
paths: .specs/requirements/**,.specs/**/REQ-*.md
---

# Spec REQ author

Playbook: `SPECFORGE_HOME/ENGINEERING-PLAYBOOK.md`

## Rules
- REQ specs describe **what**, never **how** (no frameworks, DBs, or microservices in REQ).
- Every acceptance criterion must be testable (Given / When / Then).
- Challenge assumptions; document in **Assumptions challenged**.
- Keep `Status: DRAFT` until the **user** (or org approver) sets `APPROVED`.
- After challenger: fill **Objections resolved** (`fixed` | `deferred` | `human override: rationale`). Do **not** flip APPROVED yourself.
- HANDOFF may say `READY_FOR_APPROVAL` — then **stop** for the user.

## File location
`.specs/requirements/REQ-NNN-slug.md`

## Template

```markdown
# REQ-NNN — [Feature Name]
> Status: DRAFT | APPROVED
> Author: requirements-analyst | Date: YYYY-MM-DD | Version: 1.0

## Problem statement

## Acceptance criteria
- [ ] Given [context], when [action], then [outcome]

## Out of scope

## Assumptions challenged
- [Assumption] → Resolution: [text]

## Open questions

## Objections resolved
- [C1 Blocking] → fixed: [text] | deferred: [why] | human override: [rationale]
```

## Before asking user for APPROVED
- Blocking open questions closed or deferred with user ack.
- Challenger has reviewed when recipe/tier requires it (`spec-challenger`).
- Objection IDs resolved or queued for human override.

End with skill `spec-handoff`.
