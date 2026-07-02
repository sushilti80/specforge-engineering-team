---
name: spec-release-metrics
description: >-
  Record release efficiency: estimated tokens, subagent counts, context-mode
  savings, quality KPIs. Use at Tier 2+ release, sprint end, or when comparing
  recipes. Writes .specs/metrics/releases/REL-*.yaml.
disable-model-invocation: true
---

# Spec release metrics

Playbook: `SPECFORGE_HOME/ENGINEERING-METRICS.md`

## When to use

- Before tagging a release (Tier 2+)
- After a pilot comparing recipes or tiers
- When executive summary §8 KPIs are requested

## Steps

1. **Collect proxies** (shell, do not paste large output into chat):

   ```bash
   bash scripts/collect-release-metrics.sh --since <prev-tag>
   bash scripts/estimate-pipeline-tokens.sh greenfield-feature --tier 2
   ```

2. **context-mode** (if installed): run `ctx stats`; record `context_mode_savings_ratio` only (one number + one sentence).

3. **Quality** from specs:
   - `specs-index.md` — REQ IDs shipped
   - Last verifier / spec-guardian HANDOFF or reports — gaps and drift counts

4. **Write** `.specs/metrics/releases/REL-<YYYY-MM-DD>.yaml` using schema in ENGINEERING-METRICS.md §7.

5. **Summarize** in ≤15 lines for humans:
   - tokens/REQ (estimated)
   - subagent runs vs gate checkpoints
   - quality: verifier gaps, drift
   - one improvement for next release

## Rules

- Label estimates `confidence: low|medium|high` — never present heuristics as billing fact.
- If billing export exists, put it in `tokens.billing_total` and set `method: billing_export`.
- Do not skip quality metrics when reporting token savings.
- Commit the YAML to git with the release.
