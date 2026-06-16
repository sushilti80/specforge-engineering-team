---
name: spec-req-author
description: >-
  Write or update REQ specs in .specs/requirements/. Use when creating
  requirements, acceptance criteria, or moving REQ from DRAFT to APPROVED.
paths: .specs/requirements/**,.specs/**/REQ-*.md
---

# Spec REQ author

Playbook: `~/.cursor/ENGINEERING-PLAYBOOK.md`

## Rules
- REQ specs describe **what**, never **how** (no frameworks, DBs, or microservices in REQ).
- Every acceptance criterion must be testable (Given / When / Then).
- Challenge assumptions; document in **Assumptions challenged**.
- `Status: APPROVED` only after challenger objections are resolved in **Objections resolved**.

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
- [Challenger objection] → Resolution: [text]
```

## Before APPROVED
- All blocking open questions closed.
- Challenger has reviewed (separate agent/skill `spec-challenger`).

End with skill `spec-handoff`.
