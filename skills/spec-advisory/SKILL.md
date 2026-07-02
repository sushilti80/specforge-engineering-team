---
name: spec-advisory
description: >-
  Readonly advisory mode — architecture review, compare options, feasibility,
  "should we", "critical review", "worth it", "review only". No file edits
  unless user explicitly asks to implement. Use skill spec-token-budget (review
  profile). Output verdict first, then detail. Writes decisions to
  .specs/decisions/ only when user confirms.
disable-model-invocation: true
---

# Spec advisory (readonly)

## Mode

- **Readonly** — do not create, edit, or delete repo files.
- Exception: user explicitly says **implement**, **apply**, **build**, **PR**, **commit**, or **add to repo**.

## Output shape (mandatory)

1. **Verdict** — 3 bullets max (yes / no / conditional).
2. **Gap table** — what exists vs missing (paths, not prose).
3. **Recommendation** — one next step (recipe + tier, or "new chat for implement").

Apply **`spec-token-budget`** profile: `advisory` (≤800 words total).

## Process

1. Read only paths needed (max 3 spec files + 2 code areas).
2. Use explore subagent for wide search — parent gets summary only.
3. External docs: raw URLs / SKILL.md — never paste HTML scrapes into chat.
4. Do not duplicate content already in `SPECFORGE_HOME/` docs — link paths.

## After advisory

If user approves direction:

1. Write `.specs/decisions/DEC-NNN-<slug>.md` (optional Tier 1+) **only when asked to record**.
2. Tell user: **start a new chat** for implementation with:

```
Recipe: [id] | Tier: [n]
Read: .specs/decisions/DEC-NNN.md (or paths from verdict)
Do not use prior chat summaries.
```

## Recipes

Orchestrator maps advisory intent to meta recipe **`advisory-only`** (see ENGINEERING-RECIPES.md).
