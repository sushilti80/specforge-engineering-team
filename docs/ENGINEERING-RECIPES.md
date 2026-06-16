# Engineering orchestrator — workflow recipes

Recipes are **named flows** the `eng-orchestrator` selects by work type. Each recipe lists agents, gates, and which spec artifacts are required.

**Invoke:** `/eng-orchestrator [recipe: bug-fix] Fix login timeout on session refresh`  
Or: `Use recipe maintenance to upgrade React 18 → 19`

---

## Recipe index

| Recipe ID | When to use | Spec depth | Typical lead time |
|-----------|-------------|------------|-------------------|
| `new-application` | Greenfield product | Full REQ-001 + ARCH-000 | High |
| `greenfield-feature` | New capability in existing app | Full REQ + ARCH | High |
| `bug-fix` | Defect in production or QA | Light (BUG + REQ link) | Low–medium |
| `hotfix` | Urgent production defect | Minimal BUG + parent REQ | Low |
| `maintenance` | Deps, refactors, tech debt | ADR or ARCH delta | Medium |
| `infra-change` | Terraform, CI/CD, K8s | ARCH/ADR + platform | Medium |
| `spec-only` | Requirements or design only | REQ and/or ARCH, no code | Low |
| `security-patch` | CVE or security finding | BUG or REQ + security-reviewer | Low–medium |

---

## Shared gates (all recipes)

| Gate | Meaning |
|------|---------|
| **G-spec** | Relevant spec files exist and are not in contradictory DRAFT state |
| **G-test** | `test-runner` green for scope of change |
| **G-review** | No open **Critical** from required reviewers |
| **G-verify** | `verifier` passed against linked REQ (or recipe-specific checklist) |
| **G-drift** | `spec-guardian` no blocking drift (required before merge for production recipes) |

Full feature gates **G1–G4** from the playbook apply only to `new-application` and `greenfield-feature`.

---

## Recipe: `new-application`

**Goal:** Stand up `.specs/` and first production-ready vertical slice.

```
1. Scaffold .specs/ (template if missing)
2. requirements-analyst → REQ-001 product scope (DRAFT)
3. challenger → objections
4. requirements-analyst → REQ-001 APPROVED
5. architect → ARCH-000 system overview (DRAFT)
6. challenger → objections
7. architect → ARCH-000 APPROVED + initial ADRs + contracts
8. [Pick greenfield-feature for first feature REQ-002+]
```

**Gates:** G1, G2, G4 (full playbook).

---

## Recipe: `greenfield-feature` (default)

**Goal:** New feature with full traceability.

```
requirements-analyst → REQ (DRAFT)
challenger
requirements-analyst → REQ APPROVED
architect → ARCH + ADRs + contracts (DRAFT)
challenger
architect → ARCH APPROVED
implementers (parallel per ARCH)
qa-engineer → TP-NNN
test-runner
code-reviewer ∥ security-reviewer
verifier (REQ + code only)
spec-guardian
```

**Gates:** G1, G2, G3, G4, G-drift.

**Skip:** None for production merge.

---

## Recipe: `bug-fix`

**Goal:** Fix a defect; preserve traceability to original requirement.

**Spec artifact:** `.specs/maintenance/BUG-NNN-short-title.md` (create folder if needed)

```markdown
# BUG-NNN — [title]
> Status: OPEN | FIXED
> Parent REQ: REQ-NNN
> Severity: critical | high | medium | low

## Observed behavior
## Expected behavior (from REQ acceptance criterion if applicable)
## Root cause (filled by debugger)
## Fix scope
## Regression tests required
```

**Flow:**
```
1. debugger → root cause + minimal fix proposal (read parent REQ-NNN)
2. [If root cause is spec ambiguity] requirements-analyst → patch REQ (minor version bump) OR adr-recorder
3. implementer (backend/frontend/fullstack as needed)
4. test-runner → add/run regression tests
5. code-reviewer (readonly)
6. [If auth/data/security touched] security-reviewer
7. verifier → parent REQ-NNN + BUG acceptance + tests (not implementer handoff)
8. spec-guardian → if contracts or REQ changed
9. Update BUG status FIXED; note in .specs/CHANGELOG.md
```

**Gates:** G-spec (parent REQ exists), G-test, G-review (code-reviewer), G-verify, G-drift if specs/contracts touched.

**Skip:** Full ARCH cycle unless fix changes architecture (then use `maintenance` recipe).

**Challenger:** Optional for BUG doc if severity ≤ medium; **required** if REQ patch changes acceptance criteria.

---

## Recipe: `hotfix`

**Goal:** Expedited production fix; smallest safe change.

**Flow:**
```
1. debugger → diagnose + minimal fix
2. implementer
3. test-runner → smoke + targeted regression
4. security-reviewer (if security-adjacent)
5. verifier → parent REQ + critical path only
6. spec-guardian (quick drift check)
7. BUG-NNN or CHANGELOG entry (can be brief)
```

**Gates:** G-test, G-verify (abbreviated checklist OK).

**Skip:** challenger on new ARCH; full qa-engineer TP unless high risk.

**Post-merge:** Within 48h (human policy), backfill BUG doc and REQ patch if skipped.

---

## Recipe: `maintenance`

**Goal:** Dependencies, refactors, performance work without new user-facing features.

**Spec artifact:** ADR and/or ARCH section update; optional `REQ-NNN-maintenance` for large work.

**Flow:**
```
1. architect OR adr-recorder → ADR / ARCH delta (DRAFT) describing change + rollback
2. challenger (required if behavior or contracts may change)
3. architect → APPROVED / ADR accepted
4. implementer(s)
5. test-runner (full suite if dep major version)
6. code-reviewer ∥ security-reviewer (if deps touch auth/crypto/network)
7. verifier → ADR acceptance criteria + tests
8. spec-guardian
```

**Gates:** G-spec, G-test, G-review, G-verify, G-drift.

**Skip:** New REQ unless user-visible behavior changes (then use `greenfield-feature`).

---

## Recipe: `infra-change`

**Goal:** IaC, CI/CD, environments, observability.

**Flow:**
```
1. architect → ARCH infra section or ADR (DRAFT)
2. challenger
3. architect → APPROVED
4. platform-engineer
5. sre-devops → pipeline / deploy / alerts
6. test-runner → plan/validate/lint per repo
7. security-reviewer (IAM, secrets, network)
8. verifier → ARCH infra criteria
9. spec-guardian
```

**Gates:** G1-lite (ARCH/ADR approved), G-test, G-review, G-verify, G-drift.

---

## Recipe: `spec-only`

**Goal:** Discovery, REQ/ARCH authoring, no implementation.

**Flow:**
```
requirements-analyst → REQ (DRAFT)
challenger
requirements-analyst → REQ APPROVED
[Optional] architect → ARCH (DRAFT) → challenger → APPROVED
```

**Gates:** Challenger on each APPROVED artifact.

**Skip:** All implementers, test-runner, verifier (unless user asks for feasibility spike).

---

## Recipe: `security-patch`

**Goal:** CVE, penetration finding, or security regression.

**Flow:**
```
1. security-reviewer → scope and severity
2. BUG-NNN or REQ patch
3. implementer (minimal)
4. test-runner + security-reviewer (re-scan)
5. verifier → security acceptance criteria
6. spec-guardian
```

**Gates:** G-test, G-review (security-reviewer required), G-verify, G-drift.

**Skip:** challenger on BUG unless REQ acceptance criteria change.

---

## Orchestrator selection rules

| User intent signals | Recipe |
|---------------------|--------|
| "new app", "greenfield", "from scratch" | `new-application` |
| "feature", "add capability", "build" | `greenfield-feature` |
| "bug", "fix", "defect", "regression" | `bug-fix` |
| "hotfix", "production down", "urgent" | `hotfix` |
| "upgrade", "bump", "refactor", "tech debt" | `maintenance` |
| "terraform", "pipeline", "deploy", "k8s" | `infra-change` |
| "write requirements only", "design only" | `spec-only` |
| "CVE", "vulnerability", "security fix" | `security-patch` |

When ambiguous, ask one question: **"Is this new capability, a defect, or maintenance?"**

Always state in HANDOFF: `**Recipe:** [id]` and `**Next step:** [agent]`.

Update `.cursor/agent-memory/` at recipe start/end (see `spec-agent-memory` skill).

After each gate: **checkpoint to disk** (specs, specs-index, orchestrator memory, optional `.specs/handoffs/`) then **fresh subagent with paths only** — see playbook Principle 8.

---

## Productionize checklist (per repo)

When a project leaves prototype:

1. [ ] `.specs/` in git
2. [ ] `.cursor/rules/spec-driven.mdc` (or equivalent)
3. [ ] Copy `spec-*` skills to `.cursor/skills/` (optional)
4. [ ] Agree default recipe per work type in team README
5. [ ] Define hotfix backfill policy
6. [ ] CI fails if `spec-guardian` reports blocking drift (future automation)
