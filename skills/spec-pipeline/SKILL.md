---
name: spec-pipeline
description: >-
  Spec-driven pipeline entry: need checklist → smallest recipe × tier → minimal
  agent plan. Defers to ENGINEERING-RECIPES.md §0. Not a full-ceiling mandate.
disable-model-invocation: true
---

# Spec-driven pipeline

**Authoritative right-sizing:** `SPECFORGE_HOME/ENGINEERING-RECIPES.md` §0 (need → choose → matrix R/O/— → adapt).  
**Orchestrator:** `agents/eng-orchestrator.md` · skill **`spec-recipes`**.  
Playbook: `SPECFORGE_HOME/ENGINEERING-PLAYBOOK.md`.

This skill is a **cheat sheet**, not a mandate to run every agent.

## 1. Start here (every time)

1. Run need checklist (intent, urgency, capability, contracts, novelty, knowledge, scope, parent REQ).
2. Pick **smallest** recipe — **no default** production recipe.
3. Build plan from recipe×tier matrix: list **R** agents; add **O** only with checklist reason; state **skipped**.
4. Stop for **user** `APPROVED` / override / waive — agents do not self-approve.
5. Adapt mid-flight if evidence changes; announce before continuing.

Invoke: `/eng-orchestrator [goal]` (optional `recipe:` hint — may reclassify).

## 2. Recipes (quick)

| Recipe | When | Plan shape |
|--------|------|------------|
| `advisory-only` / `docs-touch` / `vendor-sync` | Meta | Readonly / docs / harness |
| `spec-only` | Specs, no code | Analyst → user APPROVED (± challenger) |
| `bug-fix` | Defect | debugger → implement → test → review → verify |
| `hotfix` | Prod-urgent only | Minimal + abbreviated verify; review ≤48h if deferred |
| `maintenance` | No new capability | ADR → implement → test → verify |
| `infra-change` | IaC/CI/env | ARCH/ADR → platform/sre → test → verify |
| `security-patch` | CVE | security → implement → re-scan → verify |
| `greenfield-feature` (`capability`) | New user-facing capability | **Minimal first** (see matrix); not “always full team” |
| `new-application` | New product | REQ-001 → ARCH-000 if T2+ or durable boundary → then capability slice |

## 3. Gates (only those implied by **R** agents)

| Gate | When required |
|------|----------------|
| G1 REQ user-APPROVED | Before architect / implementers per matrix |
| G2 ARCH user-APPROVED | When ARCH is **R** for this tier |
| G3 tests + Critical-clear | Before verifier when test/review are **R** |
| G4 verify + Blocking drift clear | Before DONE when verifier/guardian are **R** |

Human owns APPROVED, overrides, Critical waivers, Blocking-drift waivers. Loops ≤2 rounds.

**Conflict:** recipes omit/skip wins unless checklist flags risk — do not “add agents to be safer” by default.

## 4. Minimal examples (not ceilings)

**Capability Tier 1:** REQ → **user APPROVED** → implementer → test-runner → verifier  

**Bug-fix Tier 1:** debugger (BUG) → implementer → test-runner → code-reviewer → verifier  

**Hotfix:** debugger → implementer → test-runner → verifier (+ security if adjacent)

Full ASCII of every agent is a **Tier 3 ceiling**, not the default path. See recipes matrix.

## 5. Principle 8

After each gate: update specs + memory (include **agents_planned**) → optional GATE file → **fresh subagent** with paths only.

## 6. Invoke map

| Phase | Agent / skill |
|-------|----------------|
| Orchestrate | `/eng-orchestrator` + `spec-recipes` |
| REQ | `/requirements-analyst` + `spec-req-author` (**user** APPROVED) |
| Challenge | `/challenger` + `spec-challenger` |
| ARCH | `/architect` + `spec-arch-author` (**user** APPROVED) |
| Implement | backend / frontend / fullstack / mobile / data / platform / sre |
| QA / test / review / verify / drift | qa-engineer, test-runner, reviewers, verifier, spec-guardian |

## 7. New app

```bash
bash scripts/bootstrap-project.sh ./your-app
```

Then: `/eng-orchestrator Build [app]. Recipe from need checklist — start new-application then capability Tier 1 minimal unless risk says otherwise.`

## Skills map

| Skill | Role |
|-------|------|
| `spec-recipes` | Need-based recipe selection (primary) |
| `spec-pipeline` | This entry cheat sheet |
| `spec-req-author` / `spec-arch-author` | Write DRAFT specs |
| `spec-challenger` | Adversarial review (capped) |
| `spec-handoff` | End-of-phase HANDOFF |
| `spec-verifier` / `spec-guardian-drift` | Verify / drift |
| `spec-token-budget` / `spec-advisory` / `spec-vendor-sync` | Token / meta |
| `spec-release-metrics` | Release YAML |
| `ponytail` / `ponytail-review` | Minimal code / Gate 3 bloat |
