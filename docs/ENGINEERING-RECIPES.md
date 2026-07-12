# Engineering orchestrator — workflow recipes

Recipes are **named process budgets**. The `eng-orchestrator` must **identify need first**, start from the **minimal required plan** for that recipe × tier, **add** agents only when the checklist demands them, then **adapt** if evidence changes.

Authoritative approvals/loops: `agents/eng-orchestrator.md` + `SPECFORGE_HOME/ENGINEERING-PLAYBOOK.md`.  
This file owns: **when** to use each recipe, **recipe × tier required/optional/skip**, and **reclassification**.

**Conflict rule:** On recipe vs matrix conflict, **omit/skip in this file wins** unless the need checklist explicitly flags risk (contracts, auth, PII, prod-urgent, CVE). Do not “stricter = more agents.”

**Invoke:** `/eng-orchestrator Fix login timeout on session refresh`  
(Optional hint: `recipe: bug-fix` — orchestrator may still reclassify after need check.)

**Alias:** `capability` / `feature-change` = `greenfield-feature` (prefer saying “capability recipe” in chat; keep ID `greenfield-feature` for compatibility).

---

## 0. Identify need → choose → adapt (mandatory)

Do **not** keyword-map the first verb to a recipe.

### Step A — Need checklist

| Dimension | Ask | How it steers |
|-----------|-----|----------------|
| Intent | Ship fix, add capability, change platform, decide, docs, sync? | Primary recipe family |
| Urgency | Prod-down / data loss / active exploit? | `hotfix` / `security-patch` only if yes |
| Capability | New user-facing capability (not just copy/error-string polish)? | yes → capability recipe; tiny UX polish may stay bug/maintenance |
| Contracts | Schema, public API, auth, deploy topology change? | Add ARCH/ADR; raise tier |
| Novelty | New product vs existing app vs new module/service in monorepo? | `new-application` vs capability; monorepo module still capability/maintenance by behavior |
| Knowledge | Known defect vs discovery? | bug/hotfix vs advisory/spec-only |
| Scope | Code / specs only / infra only / docs only? | Constrains recipe |
| Parent REQ | Does a parent REQ exist for this behavior? | If missing → stub / BUG-scoped verify / escalate (see § Missing parent REQ) |

If ambiguous, ask **at most two**:
1. **"Ship a fix, add a capability, change platform, or decide/docs only?"**
2. **"Prod-urgent / security-urgent, or normal priority?"**

### Step B — Smallest matching recipe

| Need | Recipe ID | Notes |
|------|-----------|-------|
| Spike / research, no ship | Tier 0 note or `advisory-only` | No fake APPROVED |
| Readonly review / should we | `advisory-only` | New chat to implement |
| Docs only | `docs-touch` | |
| Vendor/skill sync | `vendor-sync` | |
| Specs only | `spec-only` | |
| New product | `new-application` | Then capability recipe for first slice |
| New user-facing capability | `greenfield-feature` (`capability`) | Start minimal; add by tier |
| Defect, normal priority | `bug-fix` | |
| Prod-urgent break | `hotfix` | Downgrade if not urgent |
| Deps/refactor, no new capability | `maintenance` | |
| IaC/CI/env/observability | `infra-change` | |
| CVE / security finding | `security-patch` | |

**No default production recipe.**

### Step C — Recipe × tier matrix (operable)

Legend: **R** = required · **O** = optional (add if checklist flags risk) · **—** = skip

| Recipe \\ Tier | Analyst/ADR | Challenger | Architect | Implementer* | QA TP | Test-runner | Code-review | Security | Verifier | Guardian |
|----------------|-------------|------------|-----------|--------------|-------|-------------|-------------|----------|----------|----------|
| `greenfield-feature` T1 | R (REQ) | O | O† | R | O | R | O | O | R | O |
| `greenfield-feature` T2 | R | R | R | R | R | R | R | O‡ | R | R |
| `greenfield-feature` T3 | R | R | R | R | R | R | R | R | R | R |
| `bug-fix` T1 | — | — | — | R | — | R | R | O‡ | R | O§ |
| `bug-fix` T2–3 | O¶ | O¶ | — | R | O | R | R | O‡ | R | O§ |
| `hotfix` any | — | — | — | R | — | R | O# | O‡ | R | O§ |
| `maintenance` T1 | R (ADR) | O | O | R | — | R | O | O‡ | R | O§ |
| `maintenance` T2–3 | R | O¶ | O | R | — | R | R | O‡ | R | R |
| `infra-change` T1 | R (ADR/ARCH brief) | O | O | platform and/or sre | — | R | O | O‡ | R | O§ |
| `infra-change` T2–3 | R | R | R | platform → sre | — | R | O | R | R | R |
| `security-patch` any | O¶ | O¶ | — | R | — | R | O | R | R | O§ |
| `spec-only` any | R | O/R** | O | — | — | — | — | — | — | — |
| `new-application` T1 | R (REQ-001) | O | O† (ARCH-000) | via follow-on capability | — | when coding | when coding | when coding | when coding | when coding |
| `new-application` T2–3 | R | R | R (ARCH-000) | via follow-on capability | — | when coding | when coding | when coding | when coding | when coding |

\* Route implementer by surface (backend/frontend/mobile/data/fullstack/platform/sre).  
† ARCH required at T1 only if durable boundary (schema/API/security/deploy/framework).  
‡ Security if auth/PII/crypto/network/IAM/trust boundary touched.  
§ Guardian if specs/contracts changed or Tier 2+ release.  
¶ If REQ/acceptance criteria change → analyst + challenger + **user APPROVED**.  
# Hotfix: code-reviewer optional pre-merge; if skipped, **human ACK on disk** or post-merge review within **48h** (same backfill window).  
\*\* Challenger required before user APPROVED when recipe uses challenger; Tier 1 consequential approvals should still challenge.

### Step D — Adapt mid-flight

Announce recipe/tier change in chat + memory **before** continuing. Restart from earliest invalidated gate.

| Evidence | Action |
|----------|--------|
| Hotfix but not prod-impacting | → `bug-fix` |
| Bug changes API/schema/arch **without** new user capability | → `maintenance` |
| Bug/change adds **new user capability** | → `greenfield-feature` |
| Feature has no real capability (polish only) | → `maintenance` or `bug-fix` |
| Refactor adds user capability | → `greenfield-feature` |
| Defect is CVE / active vuln | → `security-patch` |
| Feature needs new env/IAM/cluster | Primary capability + `infra-change` add-on (checkpoint between) |
| Spec ambiguity root cause | Pause; analyst / adr-recorder / user |
| Advisory says build | **New chat** + production recipe + paths (if user insists same chat: checkpoint + re-run §0, still human APPROVED) |
| Risk higher (PII, payments, multi-service) | Promote tier; add O→R agents per matrix |
| No parent REQ for bug/hotfix | See **Missing parent REQ** below |

### Missing parent REQ

For `bug-fix` / `hotfix` when no parent REQ exists:

1. Prefer create stub REQ via `requirements-analyst` (DRAFT→user APPROVED) if behavior should become durable, **or**
2. BUG-only verify: verifier uses BUG acceptance + critical path; HANDOFF `parent_REQ: none — BUG-scoped`, **or**
3. Escalate to user to choose (1) or (2).

Do not invent product behavior in code to compensate for missing REQ.

### Composition

One primary recipe. Second recipe only when surfaces separate (capability + infra). Checkpoint between. Gates apply per surface from the matrix.

---

## Recipe index

| Recipe ID | Aliases | When | Weight |
|-----------|---------|------|--------|
| `new-application` | | New product | High |
| `greenfield-feature` | `capability`, `feature-change` | New user-facing capability | Ceiling high; start minimal |
| `bug-fix` | | Defect, normal priority | Low–medium |
| `hotfix` | | Prod-urgent defect | Low |
| `maintenance` | | Deps/refactor, no new capability | Medium |
| `infra-change` | | Platform/CI/env/observability | Medium |
| `spec-only` | | Specs without code | Low |
| `security-patch` | | CVE / security finding | Low–medium |

### Meta recipes

| Recipe ID | When | Edits? |
|-----------|------|--------|
| `advisory-only` | Review/feasibility | Readonly until user says implement |
| `vendor-sync` | Sync third-party skills | Harness only |
| `docs-touch` | README/ROADMAP/docs | Docs only |

Skills: `spec-advisory`, `spec-token-budget`, `spec-vendor-sync`.

---

## Shared gates (reference)

| Gate | Meaning |
|------|---------|
| G-spec | Required specs exist; not contradictory DRAFT |
| G-test | test-runner green for claimed scope (report path) |
| G-review | No open Critical from **required** reviewers |
| G-verify | verifier passed in-scope criteria (report + SHA) |
| G-drift | guardian no Blocking drift |

Only require gates implied by **R** agents in the matrix. Human owns APPROVED / overrides / waivers. Loops ≤2 rounds.

---

## Recipe: `new-application`

**Goal:** Product-scope backbone; first slice via `greenfield-feature` / capability.

**Minimal (Tier 1)**
1. Scaffold `.specs/` if missing  
2. REQ-001 DRAFT → challenger only if consequential → **user APPROVED**  
3. ARCH-000 **optional** unless durable boundary (API/schema/auth/deploy) — same APPROVED rule if present  
4. Hand off to capability recipe for first coding slice  

**Add if Tier 2+ / multi-service:** ARCH-000 required; challenger before APPROVED; fuller ADRs/contracts before slice.

**Adapt:** Discovery only → `spec-only`.

---

## Recipe: `greenfield-feature` (capability)

**Goal:** New user-facing capability. **Build plan from matrix row, not from a full pipeline.**

**Minimal (typical Tier 1)**  
REQ DRAFT → **user APPROVED** → implementer(s) → test-runner → verifier  

**Add if checklist/tier (in order)**  
- Challenger before APPROVED when consequential or Tier 2+  
- Architect + contracts when durable boundary or Tier 2+  
- QA TP when criteria non-trivial or Tier 2+  
- code-reviewer Tier 2+ (Tier 1 optional)  
- security-reviewer if trust boundary  
- spec-guardian Tier 2+ or contracts/specs changed  

**Human:** Approves REQ/ARCH; overrides in Objections resolved / ADR.

---

## Recipe: `bug-fix`

**Goal:** Fix defect with durable BUG artifact.

**Spec:** `.specs/maintenance/BUG-NNN-short-title.md` (include Reproduction, Spec gap?, Parent REQ or `none`).

**Minimal**  
debugger (BUG) → implementer → test-runner → code-reviewer → verifier (REQ+BUG or BUG-scoped)  

**Add if**  
- Spec gap → analyst/adr/user (stop inventing behavior)  
- Auth/PII/trust → security-reviewer  
- Specs/contracts changed → guardian  
- Missing parent REQ → § Missing parent REQ  

**Adapt:** no new capability but API/schema/arch → `maintenance`; new capability → `greenfield-feature`; CVE → `security-patch`; prod-down → `hotfix`.

---

## Recipe: `hotfix`

**Goal:** Prod-urgent minimal fix. **Only if urgency is real.**

**Minimal**  
debugger → implementer → test-runner (smoke + targeted regression; coverage claim) → verifier  

**Verify bar (abbreviated):** Map BUG expected behavior + critical user path from parent REQ if any; cite SHA + test report; unmet critical path = fail. Do not claim full REQ coverage.

**Review bar:** Prefer code-reviewer before merge. If skipped for speed: write `hotfix_review: deferred` + human ACK in checkpoint/BUG, and complete code-review (and security if adjacent) within **48h** backfill. Security-reviewer still **R** if security-adjacent before merge when practical; else same 48h + human ACK.

**Add if:** security-adjacent → security-reviewer; specs touched → guardian.

**Adapt:** Not urgent → `bug-fix` immediately. Missing parent REQ → § Missing parent REQ.

**Post-merge 48h:** BUG + CHANGELOG + deferred review + REQ stub/patch if needed.

---

## Recipe: `maintenance`

**Goal:** Deps/refactor/perf — no new user capability.

**Minimal**  
ADR (or brief ARCH delta) → **user accept** → implementer → test-runner → verifier  

**Add if:** behavior/contracts may change → challenger; Tier 2+ → code-reviewer + guardian; auth/crypto/network deps → security-reviewer.

**Adapt:** New capability appears → `greenfield-feature`. Pure CI/IaC → `infra-change`.

---

## Recipe: `infra-change`

**Goal:** IaC / CI / env / observability topology.

**Minimal**  
ARCH/ADR brief → **user APPROVED** → platform and/or sre (by surface) → test-runner (plan/validate/lint) → verifier  

**Add if:** Tier 2+ → challenger + fuller ARCH + guardian; IAM/secrets/network → security-reviewer; both platform and sre when modules and pipelines both change (platform first).

**Adapt:** App capability dominates → primary `greenfield-feature` + infra add-on.

---

## Recipe: `spec-only`

**Minimal**  
REQ DRAFT → (challenger if consequential/Tier 2+) → **user APPROVED**  

**Add if:** design needed → ARCH same pattern.

**Skip:** implementers/test/verify unless feasibility spike requested.

**Adapt:** Implement → new chat + production recipe + paths.

---

## Recipe: `security-patch`

**Minimal**  
security-reviewer (scope) → BUG/REQ note → implementer → test-runner → security re-scan → verifier  

**Add if:** acceptance criteria change → analyst + challenger + user APPROVED; specs/contracts changed → guardian.

**Adapt:** Not security → `bug-fix`.

---

## Orchestrator output (every selection)

- **Need summary**
- **Recipe** (+ alias) + **Tier**
- **Plan:** list **R** agents from matrix; list **O** added and why; list skipped
- **Next agent** + **gates in force**
- **Adapt watchers**
- **parent_REQ:** path | none (BUG-scoped) | stubbing

Checkpoint → fresh subagent with paths only (Principle 8).

---

## Productionize checklist (per repo)

1. [ ] `.specs/` in git  
2. [ ] Spec-driven rule enabled  
3. [ ] Team agrees need → recipe norms (not “always greenfield”)  
4. [ ] Hotfix 48h backfill + deferred review policy  
5. [ ] Named humans for APPROVE / waive  
