---
name: spec-pipeline
description: >-
  Spec-driven engineering pipeline gates and agent invoke cheat sheet. Use when
  starting a feature, new app, or orchestrating REQ→ARCH→implement→verify.
disable-model-invocation: true
---

# Spec-driven pipeline

Playbook: `SPECFORGE_HOME/ENGINEERING-PLAYBOOK.md` (or plugin `docs/ENGINEERING-PLAYBOOK.md`)  
Recipes: `SPECFORGE_HOME/ENGINEERING-RECIPES.md` · skill `spec-recipes`  
Harness: `specforge-engineering-team` — install with `bash scripts/install.sh` (Cursor) or `bash scripts/install-all.sh`

## Recipes (production)

| Recipe | When |
|--------|------|
| `greenfield-feature` | New capability (full pipeline below) |
| `bug-fix` | Defect — BUG-NNN + parent REQ |
| `hotfix` | Urgent fix — minimal gates |
| `maintenance` | Deps / refactor — ADR + challenger |
| `infra-change` | IaC / CI / K8s |
| `new-application` | Greenfield product |
| `spec-only` | REQ/ARCH only |
| `security-patch` | CVE / security finding |

Invoke: `/eng-orchestrator recipe: bug-fix — [description]`

## Principle 8 — checkpoint + reset

After each gate: update specs + memory → optional `.specs/handoffs/GATE-*.md` → **fresh subagent** with paths only. New parent chat per REQ when done. See playbook §5.

## Gates (full feature only — do not skip)

| # | Before | Requires |
|---|--------|----------|
| 1 | `architect` | REQ `APPROVED` + challenger resolved |
| 2 | implementers | ARCH `APPROVED` + challenger resolved |
| 3 | `verifier` | tests green; no Critical from reviewers; `ponytail-review` on diff (Tier 1+) |
| 4 | DONE | verifier pass; `spec-guardian` no blocking drift |

## Pipeline

```
requirements-analyst → challenger → REQ APPROVED
architect → challenger → ARCH APPROVED + ADRs + contracts
implementers (parallel if contracts frozen)
qa-engineer → TP from REQ
test-runner
code-reviewer ∥ security-reviewer ∥ ponytail-review (skill)
verifier (REQ + code only)
spec-guardian
```

## Invoke

| Phase | Agent |
|-------|--------|
| Orchestrate | `/eng-orchestrator` |
| Requirements | `/requirements-analyst` + skill `spec-req-author` |
| Challenge | `/challenger` + skill `spec-challenger` |
| Architecture | `/architect` + skill `spec-arch-author` |
| Implement | `/backend-engineer` `/frontend-engineer` `/fullstack-engineer` |
| QA plan | `/qa-engineer` |
| Tests | `/test-runner` |
| Review | `/code-reviewer` `/security-reviewer` + skill `ponytail-review` |
| Verify | `/verifier` + skill `spec-verifier` |
| Drift | `/spec-guardian` + skill `spec-guardian-drift` |

## New app

```bash
bash scripts/bootstrap-project.sh ./your-app
```

Or copy template manually from `SPECFORGE_HOME/templates/spec-driven-app/` if installed.

Then: `/eng-orchestrator Build [app description]; run full spec pipeline from REQ-001.`

## Skills map

| Skill | Role |
|-------|------|
| `spec-req-author` | Write REQ |
| `spec-arch-author` | Write ARCH/ADR/contracts |
| `spec-challenger` | Adversarial review |
| `spec-handoff` | End-of-phase HANDOFF block |
| `spec-verifier` | Verify vs REQ |
| `spec-guardian-drift` | Drift audit |
| `spec-pipeline` | This cheat sheet |
| `ponytail` | Minimal code ladder (implementers) |
| `ponytail-review` | Diff audit for over-engineering (Gate 3) |
| `ponytail-audit` | Repo-wide bloat audit (maintenance recipe) |
| `ponytail-debt` | Harvest `ponytail:` deferred shortcuts |
