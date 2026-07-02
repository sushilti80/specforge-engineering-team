---
name: spec-token-budget
description: >-
  Token and output budgets by task type. Use for every agent phase, orchestrator
  delegation, and HANDOFF. Profiles: advisory, feasibility, implement, handoff,
  docs-touch, release. Verdict-first responses; no tool dumps in chat.
disable-model-invocation: true
---

# Spec token budget

## Profiles (pick one per turn)

| Profile | Max output | Input discipline |
|---------|------------|------------------|
| **advisory** | 800 words | Max 3 files read; explore subagent for search |
| **feasibility** | 400 words + table | Platform matrix only; no install unless asked |
| **implement** | HANDOFF + diff summary | Read approved specs only; no chat history |
| **handoff** | 500 words | Paths + blockers only; no narrative replay |
| **docs-touch** | 600 words | Whitelist paths only (README, docs/, ROADMAP) |
| **release** | 15 lines + YAML path | Run collect/estimate scripts; paste summaries not logs |

## Mandatory rules

1. **Verdict first** — 3 bullets before detail.
2. **No tool dumps** — >30 lines of output → summarize or write file and cite path.
3. **Delegation** — orchestrator ≤500 words, mostly paths (Principle 8).
4. **HANDOFF** — max 5 key decisions; next agent gets paths not this block pasted.
5. **External fetch** — prefer `raw.githubusercontent.com`; skip HTML repo pages.
6. **Uploads** — if user attached a doc, do not re-fetch the same URL.

## Compression (Gate / subagent end)

If response or HANDOFF feels long:

- Drop repeated playbook explanations — cite `SPECFORGE_HOME/ENGINEERING-PLAYBOOK.md`.
- Replace paragraphs with a table.
- Set **For next agent** to path list only.

Hook reminder: subagentStop may ask for compression before next delegation.

## Orchestrator

State in every delegation: `Token profile: [name]`
