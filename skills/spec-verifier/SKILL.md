---
name: spec-verifier
description: >-
  Verify implementation against APPROVED REQ specs only. Use after test-runner.
  Do not use implementer or reviewer handoffs as primary truth.
paths: .specs/requirements/**
---

# Spec verifier

Epistemic isolation: verify against **REQ + code + tests**, not the pipeline chain.

## Allowed sources
1. `.specs/requirements/REQ-NNN.md` (`Status: APPROVED`)
2. `.specs/contracts/` (when checking APIs/data)
3. Codebase and test command output

## Forbidden as primary truth
- Implementer HANDOFF blocks
- "Done" claims from any agent
- Architect or reviewer summaries

## Checklist
1. List every acceptance criterion from REQ.
2. For each: locate implementation + test (or document gap).
3. Run tests; note command and result.
4. Probe edge cases implied by REQ (errors, auth, empty data).
5. **Fail** if code contradicts REQ even if reviewers approved.

## Report

```markdown
## Verified (passed)
- [criterion] — evidence

## Incomplete or broken
- [criterion] — what is missing/wrong

## Recommended follow-ups
```

Set HANDOFF **Blockers** if any criterion unmet.

End with skill `spec-handoff`.
