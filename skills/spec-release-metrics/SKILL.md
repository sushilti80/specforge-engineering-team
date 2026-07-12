---
name: spec-release-metrics
description: >-
  Record release efficiency against need-based plans: planned vs run agents,
  estimated tokens (minimal mode), human gates, quality KPIs. Writes
  .specs/metrics/releases/REL-*.yaml.
disable-model-invocation: true
---

# Spec release metrics

Playbook: `SPECFORGE_HOME/ENGINEERING-METRICS.md` · recipes: `ENGINEERING-RECIPES.md` §0

## When to use

- Before tagging a release (Tier 2+ full ceremony; Tier 1 optional lightweight)
- After a pilot comparing recipes, tiers, or minimal vs ceiling
- When executive KPIs are requested

## Steps

1. **Collect proxies** (do not paste large output into chat):

```bash
   bash scripts/collect-release-metrics.sh --since <prev-tag>
   # preferred: pass agents_planned from MEMORY/HANDOFF
   bash scripts/estimate-pipeline-tokens.sh <recipe> --tier <n> --agents <comma-list>
   # fallback:
   # bash scripts/estimate-pipeline-tokens.sh <recipe> --tier <n> --mode minimal
```

2. **context-mode** (if installed): `ctx stats` → one `context_mode_savings_ratio`.

3. **Plan discipline** from orchestrator MEMORY / HANDOFFs:
   - recipe, tier, agents planned (R + accepted O), agents run
   - reclassifications, human APPROVE/override/waive counts
   - max challenge/review/guardian rounds
   - hotfix deferred reviews; parent_REQ modes

4. **Quality** from specs:
   - shipped REQ/BUG IDs
   - in-scope verifier coverage (not blanket full-REQ if hotfix/BUG-scoped)
   - Blocking vs advisory drift

5. **Write** `.specs/metrics/releases/REL-<YYYY-MM-DD>.yaml` per ENGINEERING-METRICS.md §7.

6. **Summarize** ≤15 lines: tokens/REQ (minimal estimate), ceiling overrun, human decisions, in-scope gaps, Blocking drift.

## Rules

- Default estimate mode: **`minimal`**. Label `confidence` and `method`.
- Never present heuristics as billing fact.
- Do not skip plan-discipline or quality when reporting token savings.
- Commit the YAML with the release.
