# SpecForge Engineering Team v2.0.0

**Release date:** 2026-07-11  
**Type:** Major (breaking control-plane doctrine)  
**Previous:** [v1.1.0](https://github.com/sushilti80/specforge-engineering-team/releases/tag/v1.1.0)

## Summary

v2.0.0 replaces “run the full pipeline by default” with a **need → smallest recipe × tier → minimal agents** control plane. Humans own `Status: APPROVED`, overrides, and waivers. Agents stop at `READY_FOR_APPROVAL` / DRAFT. Anti-loops are capped at **≤2 rounds**.

## Breaking changes

| Area | v1.x | v2.0.0 |
|------|------|--------|
| Recipe selection | Often recipe-first; `greenfield-feature` / full team felt like default | **No default production recipe** — need checklist → smallest recipe |
| Agent plan | Ceiling / full chain common at Tier 1 | Matrix **R / O / —**; add **O** only with risk reason; state **skipped** |
| ARCH-000 | Commonly required on `new-application` | **Optional at Tier 1** unless durable boundary (API/schema/auth/deploy); required T2–3 |
| Approvals | Soft / agent-settable in practice | **User owns** `Status: APPROVED`; agents do not self-approve |
| Challenger / review loops | Could thrash | **≤2 rounds**; R2 delta-only; then human deadlock / override |
| Conflict rule | “Stricter = more agents” | **Recipes omit/skip wins** unless checklist flags risk |
| Entry commands | `/spec-pipeline` as full run | Prefer **`/eng-orchestrator`**; `/spec-pipeline` is a cheat sheet that defers to recipes §0 |
| Codex global `AGENTS.md` | Tier 1 full chain (challenger→architect→…→guardian) | Need-first; Tier 1 minimal |
| Cloud-vendor skills | e.g. default Azure compliance on security paths | **Principle 9** — no default cloud-vendor skills |

## What’s new

### Control plane

- **`docs/ENGINEERING-RECIPES.md` §0** — need checklist, recipe×tier matrix, adapt mid-flight, human gates
- **Orchestrator HANDOFF** — Need, Recipe, Tier, `agents_planned` / `optional_added` / `skipped`, parent_REQ, Adapt watchers, Human gate
- **Anti-loops** — challenger, code/security review, guardian, implement↔test ≤2 rounds

### Agents (aligned)

All major roles rewritten or aligned to the new doctrine: `eng-orchestrator`, implementers, `architect`, `requirements-analyst`, `challenger`, `adr-recorder`, `qa-engineer`, `test-runner`, `code-reviewer`, `security-reviewer`, `debugger`, `verifier`, `spec-guardian`, `platform-engineer`, `sre-devops`. `tech-lead` deprecated for production recipes.

### Bootstrap & multi-tool

- Rewritten **`docs/BOOTSTRAP-SPEC-DRIVEN-PROJECT.md`**
- Template **`AGENTS.md`**, Codex **`AGENTS.codex.md`**, `spec-driven.mdc`, bootstrap Done tips (platform-aware)
- **`docs/MULTI-TOOL.md`** entry points prefer eng-orchestrator / need blocks

### Metrics & estimation

- **`docs/ENGINEERING-METRICS.md`** — planned vs ceiling, plan-discipline scorecard, Goodhart warnings
- **`scripts/estimate-pipeline-tokens.sh`** — `--mode minimal|ceiling` and `--agents`
- Hooks: optional recipe/tier/phase/round on metrics ledger; broader subagent-stop agent set

### Skills & commands

- `spec-pipeline`, `spec-recipes`, `spec-challenger`, `spec-verifier`, `spec-guardian-drift`, `spec-req-author`, `spec-arch-author`, `spec-release-metrics` updated for need-based plans
- Commands `eng-orchestrator` / `spec-pipeline` are need-first

## Upgrade guide

1. **Re-install** (or pull `main` / tag `v2.0.0` and re-run your platform install script) so agents, skills, and Codex `AGENTS.md` refresh.
2. **Re-bootstrap** project overlays if you customized copies of `AGENTS.md` / `spec-driven.mdc` from v1 — merge need-first prompts and Tier-1 ARCH-optional rules.
3. **Stop pasting** `Recipe: greenfield-feature` + full agent lists as the default opener. Start with **Need + Tier**; let the orchestrator pick the recipe.
4. **Approve on disk** — set `Status: APPROVED` yourself (or explicitly ask the agent to record your approval). Do not expect agents to self-approve.
5. **Tier 1 new apps** — expect REQ → user APPROVED → implementer → test-runner → verifier unless a durable boundary forces ARCH / checklist adds O agents.
6. **Re-read** `ENGINEERING-RECIPES.md` §0 and `BOOTSTRAP-SPEC-DRIVEN-PROJECT.md` before the next pilot.

## Docs map

| Doc | Role |
|-----|------|
| [`ENGINEERING-RECIPES.md`](ENGINEERING-RECIPES.md) | Authoritative need → matrix → adapt |
| [`ENGINEERING-PLAYBOOK.md`](ENGINEERING-PLAYBOOK.md) | Lifecycle, human gates, Principle 9 |
| [`BOOTSTRAP-SPEC-DRIVEN-PROJECT.md`](BOOTSTRAP-SPEC-DRIVEN-PROJECT.md) | First-run / install / bootstrap |
| [`ENGINEERING-METRICS.md`](ENGINEERING-METRICS.md) | Plan discipline + token proxies |
| [`MULTI-TOOL.md`](MULTI-TOOL.md) | Cursor / Claude / Codex / OpenCode |
| [`SPEC-DRIVEN-EXECUTIVE-SUMMARY.md`](SPEC-DRIVEN-EXECUTIVE-SUMMARY.md) | Condensed doctrine (historical banner retained) |

## Install

```bash
git clone https://github.com/sushilti80/specforge-engineering-team.git
cd specforge-engineering-team
git checkout v2.0.0
bash scripts/install-all.sh
```

Or upgrade an existing clone:

```bash
git fetch --tags
git checkout v2.0.0
bash scripts/install-all.sh   # or install.sh / install-codex.sh / …
```

## Verification smoke test

```
/eng-orchestrator

Need: advisory — explain SpecForge v2 control plane in one paragraph
Tier: 0
Suggested recipe: advisory-only
```

Expect a short readonly answer and a plan that does **not** spawn the full engineering team.

## Contributors / process note

This release is a harness control-plane overhaul (agents, recipes, bootstrap, metrics). No application product REQ ships with the tag; treat target-app pilots as separate releases using `spec-release-metrics` when measuring app work.
