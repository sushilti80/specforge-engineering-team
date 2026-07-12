# Engineering metrics — tokens & release efficiency

> Estimate and record efficiency **without fighting right-sizing**.  
> Companions: `ENGINEERING-PLAYBOOK.md` §7 · `ENGINEERING-RECIPES.md` §0 · skill `spec-release-metrics`

Last updated: 2026-07-11

---

## 1. Why estimate if we cannot meter perfectly?

Cursor and most agent hosts **do not expose per-subagent token counts** to project hooks today. Billing is session/account-level. Use **three fidelity tiers**:

| Tier | Source | Fidelity | Use |
|------|--------|----------|-----|
| **A — Billing** | Provider usage export / invoice | Exact $ (often total tokens) | Monthly reconcile; calibrate heuristics |
| **B — Session proxies** | `session.jsonl`, gate files, orchestrator MEMORY, `ctx stats` | Medium | Per-release story |
| **C — Plan heuristics** | `estimate-pipeline-tokens.sh` (**planned** matrix vs optional **ceiling**) | Low–medium (±30–50%) | Planning, A/B recipes, tier choice |

**Goal:** compare **releases, recipes, and plan discipline** over time — not fake millisecond token tracing.

**Do not** use ceiling estimates as the only planning number. Prefer **planned (matrix R + accepted O)** so metrics reward need-based omission.

---

## 2. What to measure (release scorecard)

### 2.1 Token & context

| Metric | Definition | How |
|--------|------------|-----|
| Est. input / output tokens | Completions in the release window | Heuristic (**planned**) + billing |
| Tokens (or $) per shipped REQ/BUG | A-tier cost ÷ shipped units | Release ledger |
| context-mode savings ratio | Tool output kept out of window | `ctx stats` (one number) |
| Delegation word count | Orchestrator→subagent prompts (≤500) | Sample HANDOFF / review |
| Parent chat resets | New chats / checkpoint resets per REQ | MEMORY + GATE files |

### 2.2 Plan discipline (control plane — required)

| Metric | Definition | Target / read |
|--------|------------|---------------|
| **Recipe + tier** | Selected after need checklist | From MEMORY / REL YAML |
| **Agents planned (R + accepted O)** | From recipes matrix + HANDOFF | Must be recorded |
| **Agents run** | Distinct roles in `session.jsonl` | Compare to planned |
| **Ceiling overrun** | Runs − planned (extra roles) | Trend → 0 |
| **Recipe reclassifications** | Mid-flight recipe/tier changes | Count; note reason |
| **Challenge / review / guardian rounds** | Max should be ≤2 each | From HANDOFF / MEMORY |
| **Human decisions** | APPROVE / override / defer / waive | Count (≥1 APPROVE per gated artifact) |
| **Hotfix deferred review** | Review ACK + completed ≤48h | 100% of deferred hotfixes |
| **parent_REQ mode** | path \| stub \| BUG-scoped | Record per bug/hotfix |

### 2.3 Pipeline activity

| Metric | Definition | How |
|--------|------------|-----|
| Subagent runs by role | Completions | `session.jsonl` |
| Gate checkpoints | `.specs/handoffs/GATE-*.md` | collect script |
| Parallel review wall time | Optional HANDOFF timestamps | Optional |

Low GATE count + high subagent runs → chat rot (missing Principle 8 checkpoints).

### 2.4 Quality (never optimize tokens alone)

| Metric | Definition | Target |
|--------|------------|--------|
| **In-scope criterion coverage** | Verifier-passed criteria for **claimed scope** (full REQ, REQ+BUG, or BUG-scoped / hotfix abbreviated bar) | 100% of **in-scope** |
| Verifier gaps at release | Unmet in-scope items | 0 |
| **Blocking** drift | spec-guardian Blocking open | 0 at merge (or recorded waive) |
| Advisory drift | Non-blocking drift | Track; do not fail merge alone |
| Rework after done | BUG from spec gap vs code defect | Spec-gap share trend down |
| Diff LOC | Since last tag | Context only (Ponytail) |

### 2.5 Goodhart warnings

| If you optimize… | You may get… |
|------------------|--------------|
| Tokens/REQ only | Bundled REQs, skipped human gates, under-verify |
| Gate file count | Empty GATE stubs |
| Subagent count | Artificial splits or avoided legitimate parallel work |
| context-mode ratio alone | Meaningless without quality |

A “cheap” release with Blocking drift, zero human APPROVEs, or ceiling overrun is **negative** value.

---

## 3. Estimation model (Tier C)

### 3.1 Modes

```bash
# Preferred — exact plan from HANDOFF agents_planned
bash scripts/estimate-pipeline-tokens.sh greenfield-feature --tier 1 --agents eng-orchestrator,requirements-analyst,backend-engineer,test-runner,verifier

# Fallback approximate matrix lists
bash scripts/estimate-pipeline-tokens.sh greenfield-feature --tier 1 --mode minimal

# Ceiling — stress only
bash scripts/estimate-pipeline-tokens.sh greenfield-feature --tier 3 --mode ceiling
```

| Mode | Meaning |
|------|---------|
| `--agents` | **Preferred** — exact planned list from orchestrator HANDOFF / MEMORY |
| `minimal` | Approximate **R** agents for recipe×tier (may drift from markdown matrix) |
| `ceiling` | Upper-bound full team (planning stress only) |

### 3.2 Per-agent baseline (single pass ~3 turns)

| Agent | Est. in | Est. out |
|-------|---------|----------|
| requirements-analyst | 8K | 3K |
| challenger | 6K | 2K |
| architect | 12K | 5K |
| backend / frontend / mobile / data | 15K | 8K |
| fullstack | 18K | 9K |
| debugger | 8K | 2K |
| qa-engineer | 7K | 3K |
| test-runner | 10K | 2K |
| code-reviewer / security-reviewer | 8–10K | 2K |
| ponytail-review (skill) | 6K | 1K |
| verifier / spec-guardian | 8–10K | 2–3K |
| platform / sre | 10–12K | 3–5K |
| eng-orchestrator | 20K | 4K |

Resume across gates (avoid): ×1.5–2.5 per extra turn cluster.

### 3.3 Illustrative totals (recompute with script; do not treat as law)

| Recipe × example | Mode | Ballpark in+out |
|------------------|------|-----------------|
| `hotfix` T1 | minimal | 35K–70K |
| `bug-fix` T1 | minimal | 60K–110K |
| `greenfield-feature` / `capability` T1 | minimal | 70K–140K |
| `greenfield-feature` T3 | ceiling | 200K–400K+ |
| `new-application` + first slice | mixed | 200K–500K+ |

**Do not** multiply a ceiling agent list by a large tier factor — that double-counts. Tier changes **which agents are R**, not a blind ×1.6 on the max list.

### 3.4 Adjustments

| Factor | Effect |
|--------|--------|
| context-mode | −20–40% effective tool-input vs naive |
| Ponytail on implementers | Often shorter diffs (measure via LOC, not assumed %) |
| Long parent chat (>30 turns) | +50–200% late-gate input |
| Large specs (>8K) | +linear |
| Parallel implementers | Same tokens, less wall time |
| Principle 8 fresh subagents | Often −30–50% input vs one long thread |

---

## 4. Tier A — Billing

1. Export usage for tag window.  
2. Record under `billing:` in REL YAML.  
3. Divide by shipped REQ/BUG units.  
4. Calibrate heuristics quarterly (±20% baselines).

Skip Tier A if no export.

---

## 5. Tier B — Proxies

### 5.1 `session.jsonl`

Path: `.agents/memory/_project/metrics/session.jsonl` (alias `.cursor/agent-memory/...`).

Hook fields today: `ts`, `event`, `agent`, `files_modified`, `spec_touch`.  
Optional if present on event: `recipe`, `tier`, `phase`, `round`.

**Planned agents, reclassifications, human decisions, rounds** — record in `eng-orchestrator/MEMORY.md` and/or REL YAML until hooks carry richer payloads.

```bash
bash scripts/collect-release-metrics.sh --since v1.2.0
```

### 5.2 context-mode

`ctx stats` → one `context_mode_savings_ratio` into REL YAML.

### 5.3 Gates

Each `GATE-*.md` evidences Principle 8. Pair with subagent counts.

---

## 6. Release ceremony

**Tier 2+:** full ceremony below.  
**Tier 1:** optional lightweight REL (recipe, planned vs run, in-scope verify, Blocking drift) — skip billing theater.

1. List shipped REQ/BUG IDs (`specs-index.md`).  
2. `collect-release-metrics.sh --since <tag>`.  
3. `estimate-pipeline-tokens.sh <recipe> --tier N --mode minimal` (and ceiling only if comparing stress).  
4. Skill **`spec-release-metrics`** → `.specs/metrics/releases/REL-*.yaml`.  
5. Review: tokens/REQ with quality + **ceiling overrun** + human decisions.  

---

## 7. Release YAML schema

```yaml
# .specs/metrics/releases/REL-2026-07-11.yaml
release_id: REL-2026-07-11
git_tag: v1.3.0
since_tag: v1.2.0
tier: 2
recipes: [greenfield-feature, bug-fix]  # capability alias OK in notes

reqs_shipped: [REQ-004, REQ-005]
bugs_shipped: [BUG-012]

plan:
  mode: minimal                    # minimal | ceiling | mixed
  agents_planned: [requirements-analyst, backend-engineer, test-runner, verifier]
  agents_run: [requirements-analyst, backend-engineer, test-runner, code-reviewer, verifier]
  ceiling_overrun: [code-reviewer] # run − planned (example)
  reclassifications:
    - from: hotfix
      to: bug-fix
      reason: not prod-urgent
  human_decisions:
    approvals: 2
    overrides: 0
    waivers: 0
  loops:
    challenger_max_round: 1
    review_max_round: 1
    guardian_max_round: 1
  hotfix_deferred_reviews_open: 0
  parent_req_modes: [path, bug-scoped]

tokens:
  billing_total: null
  estimated_input: 120000
  estimated_output: 40000
  estimated_total: 160000
  confidence: medium
  method: heuristic_minimal+ledger  # billing_export | heuristic_minimal | heuristic_ceiling | ledger

efficiency:
  subagent_runs: 11
  subagent_by_role:
    verifier: 2
    backend-engineer: 2
  gate_checkpoints: 5
  parent_chat_resets: 2
  context_mode_savings_ratio: 8.4
  diff_loc_added: 412
  diff_loc_removed: 98

quality:
  scope_mode: req_full              # req_full | req_plus_bug | bug_scoped | hotfix_abbreviated
  in_scope_criteria_total: 12
  in_scope_criteria_passed: 12
  verifier_gaps_at_release: 0
  spec_drift_blocking: 0
  spec_drift_advisory: 3
  ponytail_review_items: 7

notes: |
  REQ-004 minimal Tier 1 plan; no ceiling overrun.
```

---

## 8. Limits & honesty

| Cannot today | Can |
|--------------|-----|
| Per-tool token IDs in hooks | Count subagents; compare planned vs run |
| Exact parent/child split | Estimate from **planned** recipe×tier |
| ±10% token accuracy | Trend lines + quality + overrun |

---

## 9. Roadmap

| Item | Status |
|------|--------|
| `session.jsonl` via subagentStop | Shipped |
| `collect-release-metrics.sh` | Shipped |
| `estimate-pipeline-tokens.sh` `--mode minimal\|ceiling` | Shipped |
| skill `spec-release-metrics` | Shipped (plan + quality fields) |
| Richer ledger (recipe/tier/round on each event) | Partial / MEMORY until hooks improve |
| Cursor native token API | Waiting on platform |
| Auto-ingest billing CSV | Contrib |

See `ROADMAP.md` for platform work.
