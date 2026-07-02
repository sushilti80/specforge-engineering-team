# Engineering metrics — tokens & release efficiency

> How to **estimate** and **record** input/output tokens and efficiency parameters across the SpecForge pipeline.  
> Companion: `ENGINEERING-PLAYBOOK.md` §7 · Executive summary §8 · skill `spec-release-metrics`

Last updated: 2026-07-01

---

## 1. Why estimate if we cannot meter perfectly?

Cursor and most agent hosts **do not expose per-subagent token counts** to project hooks today. Billing dashboards are session/account-level. That does not block release discipline — it means we use **three fidelity tiers**:

| Tier | Source | Fidelity | Use at release |
|------|--------|----------|----------------|
| **A — Billing ground truth** | Cursor/Codex usage export, invoice | Exact $ and often total tokens | Reconcile monthly; calibrate heuristics |
| **B — Session proxies** | context-mode `ctx_stats`, metrics ledger (hooks), gate files | Medium | Per-release efficiency story |
| **C — Recipe heuristics** | `scripts/estimate-pipeline-tokens.sh` | Low–medium (±30–50%) | Planning, A/B recipes, tier choice |

**Goal:** compare **releases and recipes** over time, not pretend we have millisecond-accurate token tracing.

---

## 2. What to measure (release scorecard)

### 2.1 Token & context (efficiency)

| Metric | Definition | How to get it |
|--------|------------|---------------|
| **Est. input tokens** | Prompt + context injected to models in a release cycle | Heuristic script + billing export |
| **Est. output tokens** | Model completions in same cycle | Heuristic + billing export |
| **Token cost per shipped REQ** | (A-tier cost) ÷ count of REQ marked DONE | Release ledger |
| **context-mode savings ratio** | Bytes/tokens kept out of window vs raw tool output | `ctx stats` / MCP at session end |
| **Delegation word count** | Orchestrator prompts to subagents (target ≤500) | Sample + lint in HANDOFF review |
| **Parent chat turns** | Turns before checkpoint reset (target: new chat per REQ) | Manual or ledger |

### 2.2 Pipeline activity (structure)

| Metric | Definition | How to get it |
|--------|------------|---------------|
| **Subagent runs** | Completed subagents by role | `.agents/memory/_project/metrics/session.jsonl` |
| **Gate checkpoints** | Files under `.specs/handoffs/GATE-*.md` | `find` / release script |
| **Recipe / tier** | Which flow ran | `eng-orchestrator/MEMORY.md` or release YAML |
| **Parallel review savings (wall time)** | code ∥ security ∥ ponytail-review | Timestamps in HANDOFF (optional) |

### 2.3 Quality (do not optimize tokens alone)

| Metric | Definition | Target |
|--------|------------|--------|
| **REQ criterion coverage** | AC with test + verifier pass | 100% for merge |
| **Verifier gaps** | Open items at release | 0 |
| **Spec drift findings** | spec-guardian blocking items | 0 at merge |
| **Rework after “done”** | BUG linked to spec gap vs code | Trend down |
| **Diff LOC** | `git diff` stat since last tag | Context (Ponytail lowers bloat) |

---

## 3. Estimation model (Tier C heuristics)

### 3.1 Per-agent baseline (single gate, one pass)

Baseline assumes: **inherit model**, ~3 turns, reads 2 spec files (~2.5K tokens each), HANDOFF ~400 tokens out.

| Agent | Est. input | Est. output | Notes |
|-------|------------|-------------|-------|
| requirements-analyst | 8K | 3K | REQ draft |
| challenger | 6K | 2K | Readonly |
| architect | 12K | 5K | ARCH + contracts |
| backend-engineer | 15K | 8K | Implements slice |
| frontend-engineer | 15K | 8K | Implements slice |
| test-runner | 10K | 2K | Logs often large → use context-mode |
| code-reviewer | 8K | 2K | Diff-sized input dominates |
| security-reviewer | 10K | 2K | |
| ponytail-review (skill) | 6K | 1K | Diff only |
| verifier | 10K | 3K | REQ + codebase |
| spec-guardian | 8K | 2K | |
| eng-orchestrator | 20K | 4K | Multi-delegation parent |

Multiply by **turn factor** if subagent resumed (avoid): ×1.5–2.5 per extra turn.

### 3.2 Recipe totals (approximate ranges)

Run: `bash scripts/estimate-pipeline-tokens.sh <recipe> [--tier N]`

| Recipe | Typical subagents | Est. total tokens (in+out) |
|--------|-------------------|----------------------------|
| `hotfix` | 4–6 | 40K–80K |
| `bug-fix` | 6–8 | 80K–150K |
| `maintenance` | 5–8 | 70K–140K |
| `greenfield-feature` | 12–16 | 180K–350K |
| `new-application` | 18–25 | 350K–600K+ |

**Tier multiplier:** Tier 0 ×0.3 · Tier 1 ×1.0 · Tier 2 ×1.3 · Tier 3 ×1.6 (extra challenger/review cycles).

**Principle 8 savings:** fresh subagent per gate vs one long chat often saves **30–50% input** on later gates (no accumulated parent history). Record `checkpoint_resets` in release YAML when you enforce this.

### 3.3 Adjustments (apply in release notes)

| Factor | Effect on estimate |
|--------|-------------------|
| context-mode active | −20–40% effective input vs naive Bash/Read |
| Ponytail on implementers | −10–25% output tokens (shorter diffs) |
| Long parent chat (>30 turns) | +50–200% input on late gates |
| Large ARCH/REQ files (>8K each) | +linear with spec size |
| Parallel implementers | Same tokens, −wall time only |

---

## 4. Tier A — Billing ground truth

1. Export usage from your provider for the release window (tag `v1.2.0` → `v1.3.0` dates).
2. Record in `.specs/metrics/releases/REL-NNN.yaml` under `billing:`.
3. Divide by **shipped REQ count** for `$ / REQ` and `tokens / REQ`.
4. Calibrate heuristic script quarterly (adjust baselines ±20%).

Without export, skip Tier A — use Tier B+C only.

---

## 5. Tier B — Automated proxies (this harness)

### 5.1 Session metrics ledger

Hook **`subagentStop`** appends one JSON line per completed spec-team subagent:

```
.agents/memory/_project/metrics/session.jsonl
```

Fields: `ts`, `event`, `agent`, `files_modified`, `spec_touch`.

At release, run:

```bash
bash scripts/collect-release-metrics.sh --since v1.2.0
```

Aggregates: subagent counts by role, gate files, git diff stat, optional ledger tail.

### 5.2 context-mode

Before closing a release session (Cursor):

```
ctx stats
```

Paste **savings ratio** into release YAML (`efficiency.context_mode_savings_ratio`). Do not summarize away the ratio — one number is enough for the ledger.

### 5.3 Gate artifacts

Each `.specs/handoffs/GATE-*.md` is evidence of Principle 8. Count them per REQ — low count with high subagent runs suggests **chat rot** (missing checkpoints).

---

## 6. Release ceremony (Tier 2+)

1. Tag release branch; list REQ IDs in `specs-index.md` marked DONE.
2. Run `collect-release-metrics.sh` → draft numbers.
3. Run `estimate-pipeline-tokens.sh` per REQ recipe → compare to ledger subagent counts.
4. Invoke skill **`spec-release-metrics`** → write `.specs/metrics/releases/REL-NNN.yaml`.
5. Optional: append summary to `.specs/CHANGELOG.md` efficiency section.
6. Review: if **tokens/REQ** up but **drift/rework** down → good trade. If both up → tighten tier or enforce checkpoints.

---

## 7. Release YAML schema

```yaml
# .specs/metrics/releases/REL-2026-07-01.yaml
release_id: REL-2026-07-01
git_tag: v1.3.0
since_tag: v1.2.0
tier: 2
recipes: [greenfield-feature, bug-fix]

reqs_shipped:
  - REQ-004
  - REQ-005

tokens:
  billing_total: null          # Tier A — from export
  estimated_input: 220000      # Tier C
  estimated_output: 65000
  estimated_total: 285000
  confidence: medium           # low | medium | high
  method: heuristic+ledger     # billing_export | heuristic | ledger

efficiency:
  subagent_runs: 14
  subagent_by_role:
    verifier: 2
    backend-engineer: 3
  gate_checkpoints: 4
  parent_chat_resets: 2
  context_mode_savings_ratio: 8.4
  diff_loc_added: 412
  diff_loc_removed: 98

quality:
  verifier_gaps_at_release: 0
  spec_drift_blocking: 0
  ponytail_review_items: 7

notes: |
  REQ-004 used fresh chat per gate; REQ-005 ran in one long thread — estimate inflated ~40% on REQ-005.
```

---

## 8. Limits & honesty

| We cannot (today) | We can |
|-------------------|--------|
| Per-tool-call token IDs in hooks | Count subagent completions by role |
| Exact parent vs child token split in Cursor | Estimate from recipe + tier |
| Compare to vibe-coded without A/B discipline | Run paired features, record both ledgers |
| Guarantee ±10% token accuracy | Trend lines over releases |

**Do not** use token estimates as performance targets without quality metrics (§2.3). A “cheap” release that ships drift is negative value.

---

## 9. Roadmap (instrumentation)

| Item | Status |
|------|--------|
| `session.jsonl` via subagentStop | Shipped |
| `collect-release-metrics.sh` | Shipped |
| `estimate-pipeline-tokens.sh` | Shipped |
| skill `spec-release-metrics` | Shipped |
| Cursor native token API in hooks | Waiting on platform |
| Auto-ingest billing CSV | Community/contrib |
| Dashboard (Grafana/Canvas) | Optional |

See `ROADMAP.md` for platform work.
