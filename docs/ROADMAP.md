# SpecForge roadmap

Last updated: 2026-07-13

## Current release

| Tag | Notes |
|-----|--------|
| **[v2.1.1](RELEASE-v2.1.1.md)** | Bootstrap copies distill/estimate/collect scripts into projects; code-reviewer untrusted-content defense |
| [v2.1.0](RELEASE-v2.1.0.md) | Claude/Codex global hooks; Copilot adapter (CLI + Cloud); ForgeCode adapter; `id:` agent frontmatter |
| [v2.0.2](RELEASE-v2.0.2.md) | Release signing + cosign verify path |
| [v2.0.1](RELEASE-v2.0.1.md) | Anti-leak: spawn allowlist, path-only HANDOFF, disk-wins-over-chat |
| [v2.0.0](RELEASE-v2.0.0.md) | Need-based control plane (breaking): recipes §0, human APPROVED, ≤2-round anti-loops |
| [v1.1.0](https://github.com/sushilti80/specforge-engineering-team/releases/tag/v1.1.0) | Prior line — upgrade via install scripts |

**Doctrine (v2):** need checklist → smallest recipe × tier → minimal agents → human `Status: APPROVED` → fresh subagents with **paths only** (no chat-summary spawn). Authoritative: `ENGINEERING-RECIPES.md` §0 · `ENGINEERING-PLAYBOOK.md`.

---

## Shipped (supported today)

### Platforms

| Platform | Install | Agents | Skills | Hooks | Ponytail |
|----------|---------|--------|--------|-------|----------|
| **Cursor** | `scripts/install.sh` | 20 (plugin) | 19 | 5 | rule + skills |
| **Claude Code** | `scripts/install-claude.sh` | 20 | 19 | 5 (global) | skills |
| **Codex CLI** | `scripts/install-codex.sh` | via AGENTS.md | 19 | 5 (global) | skills |
| **Copilot CLI** | `scripts/install-copilot.sh` | 20 (`*.agent.md`) | 19 | 5 (global) | skills |
| **Copilot Cloud** | `bootstrap-project.sh --platform copilot` | 20 (`.github/agents`) | 19 (`.github/skills`) | 5 (`.github/hooks`, vendored) | skills |
| **ForgeCode** | `scripts/install-forge.sh` | 20 (symlink, `id:`+`name:`) | 19 (`~/.agents/skills`) | — (PR #2757 closed) | skills |
| **OpenCode** | `scripts/install-opencode.sh` | 20 | 19 | — | skills |

Bootstrap: `scripts/bootstrap-project.sh` · guide: `BOOTSTRAP-SPEC-DRIVEN-PROJECT.md` · parity: `MULTI-TOOL.md`.

### Control plane (v2)

| Capability | Where |
|------------|--------|
| Need → recipe × tier matrix (R/O/—) | `ENGINEERING-RECIPES.md` §0 |
| Human APPROVED / override / waive | Playbook + all phase agents |
| Anti-loops ≤2 (challenge, review, guardian, fix↔test) | Playbook + role agents |
| Plan discipline (`agents_planned` / skipped / adapt) | `eng-orchestrator` + MEMORY |
| Path-only spawn + Tier 2+ isolation | `eng-orchestrator` spawn allowlist · `spec-handoff` · v2.0.1 |
| Principle 9 — no default cloud-vendor skills | Playbook + security/platform/sre agents |
| Tier 1 ARCH-000 optional (durable boundary) | Recipes + bootstrap templates |

### Token discipline & metrics

| Item | Location |
|------|----------|
| `spec-advisory` + `spec-token-budget` | skills + `rules/token-discipline.mdc` |
| `beforeSubmitPrompt` intent hook | `hooks/scripts/prompt-intent.sh` |
| Meta recipes (`advisory-only`, `vendor-sync`, `docs-touch`) | `ENGINEERING-RECIPES.md` |
| SubagentStop checkpoint + anti-summary nudge | `hooks/scripts/subagent-stop.sh` |
| Learning-journal distill | `scripts/distill-learning-journal.sh` |
| Release metrics + estimate (`minimal` / `--agents`) | `ENGINEERING-METRICS.md` · `spec-release-metrics` |

### Ponytail

Vendored from [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) (MIT): six skills; Cursor `rules/ponytail.mdc`; `bash scripts/sync-ponytail.sh`; Gate 3 parallel with code/security review.

---

## Near-term (post-v2.0.1) — maintainers

Prioritize **adoption and honesty of the control plane** before new platforms.

| Priority | Item | Why |
|----------|------|-----|
| **1** | **Pilot matrix** | Run bug-fix T1, capability T1, hotfix in a real app; record plan-discipline + tokens via `spec-release-metrics` |
| **2** | **APPROVED evidence** | Stronger “user-owned APPROVED” signal (named approver / checkpoint) — still honor-system today |
| **3** | **Estimate ↔ matrix SoT** | Keep `estimate-pipeline-tokens.sh` locked to recipes matrix (avoid drift) |
| **4** | **README / install tips** | Smoke paths and “start here” fully match need-first entry (reduce leftover `/spec-pipeline` as default) |
| **5** | **Hotfix 48h review policy** | Document project-level ACK/backfill convention for deferred code-review |

---

## Next platform adapters — community wanted

Copilot (CLI + Cloud) and ForgeCode (agents) are now shipped. One harness (agents, skills, docs); each tool gets a thin adapter. OpenCode hooks and ForgeCode hooks are the next maintainer targets; other tools welcome in parallel.

| Priority | Tool | Likely install path | Notes | Status |
|----------|------|---------------------|-------|--------|
| **Next** | **OpenCode hooks** | plugin lifecycle API | Same 5 checkpoint events via bridge | **Help wanted** |
| 2 | **ForgeCode hooks** | `~/.forge/` hooks config | PR #2757 closed 2026-04-28; revisit when upstream ships user hooks (contract mirrors Claude Code) | **Blocked upstream** |
| 3 | **Aider** | `.aider.conf.yml`, `AGENTS.md` | No native subagents | Help wanted |
| 4 | **Windsurf** | `.windsurf/rules/` | Ponytail upstream rules | Help wanted |
| 5 | **Cline** | `.clinerules/` | Instruction-only | Help wanted |
| 6 | **Kiro** | `.kiro/steering/` | Instruction-only | Help wanted |

### Good contribution checklist

1. `scripts/install-<tool>.sh` via `scripts/lib/specforge-install.sh`
2. Bootstrap `--platform <tool>` when project-local paths are required
3. Row in `MULTI-TOOL.md` (parity + need-first quickstart)
4. Smoke notes (agents/skills load)
5. **No fork of playbook/recipes** — reuse `SPECFORGE_HOME`; adapt paths only
6. Ship **v2 doctrine** (need checklist, human APPROVED, path-only spawn) — not v1 full-pipeline defaults

### Out of scope for adapters

- Reimplementing Cursor hook *scripts* (reuse `hooks/scripts/` + platform bridge)
- Forcing all 20 agents if the tool only supports AGENTS.md + skills (document reduced mode)
- Vendor-specific model routing

### How to contribute

1. Issue: `[platform] install script for <tool>`
2. Branch `feat/install-<tool>`
3. PR: install + MULTI-TOOL + ROADMAP status
4. Merge when: idempotent install, clear docs, no secrets

---

## Later (maintainers)

| Priority | Item | Description |
|----------|------|-------------|
| 1 | Release metrics dashboard | Optional viz over `.specs/metrics/releases/` |
| 2 | OpenCode hook parity | Plugin lifecycle ≈ Cursor/Claude/Codex/Copilot gate semantics |
| 3 | ForgeCode hook parity | Revisit when ForgeCode merges user-configurable hooks upstream (PR #2757 closed) |
| 4 | Billing CSV ingest | Auto-fill Tier A token totals in release YAML |
| 5 | Ponytail auto-sync | CI: `vendor/ponytail/VERSION` matches upstream tag |
| 6 | Harder APPROVED lock | Optional file/schema check so agents cannot silently flip status |

---

## Principles

- **Specs before code** — `.specs/` is source of truth; chat is ephemeral
- **Need-based sizing** — no default production recipe; omit/skip wins unless checklist flags risk
- **Human gates** — user owns APPROVED / override / Critical & Blocking-drift waivers
- **Principle 8** — checkpoint to disk, then path-only spawn; disk wins over chat summaries
- **Supported platforms** get real skill files (not broken `vendor/` symlinks in bootstrapped projects)
- **Third-party skills** (Ponytail) stay MIT-attributed under `vendor/ponytail/`
