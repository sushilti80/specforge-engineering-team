# Engineering Team Playbook
> Spec-driven agentic engineering · Non-conformist design · Token efficiency · Human-gated approvals
>
> Last updated: 2026-07-11 | **Bootstrap:** `SPECFORGE_HOME/BOOTSTRAP-SPEC-DRIVEN-PROJECT.md` | Agents: harness `agents/` | Spec skills: harness `skills/spec-*/` | Template: harness `templates/spec-driven-app/`
>
> Authoritative agent contracts live in `agents/*.md`. This playbook must stay aligned with them.

## SPECFORGE_HOME (multi-tool)

Resolve playbook paths from the **first directory that exists** on your machine:

| Platform | SPECFORGE_HOME |
|----------|----------------|
| Cursor | `~/.cursor/` |
| Codex | `~/.codex/specforge/` |
| OpenCode | `~/.config/opencode/specforge/` |
| Claude Code | `~/.claude/docs/specforge/` |

Example: `SPECFORGE_HOME/ENGINEERING-RECIPES.md` → `~/.codex/specforge/ENGINEERING-RECIPES.md` on Codex.

See `SPECFORGE_HOME/MULTI-TOOL.md` for install and parity details.

---

## Table of Contents
1. [Core Principles](#1-core-principles)
2. [Spec-Driven Model](#2-spec-driven-model)
3. [Spec File Structure](#3-spec-file-structure)
4. [Agent Roster](#4-agent-roster)
5. [Pipeline & Handoff Protocol](#5-pipeline--handoff-protocol)
6. [Non-Conformist Design](#6-non-conformist-design)
7. [Token Efficiency Strategy](#7-token-efficiency-strategy)
8. [Rules for Future Agents](#8-rules-for-future-agents)

Key §5 subsections: [Approval authority](#approval-authority-human-gated), [Challenge / review anti-loops](#challenge--review--drift-anti-loops), [Orchestrator gates](#orchestrator-gates-enforced-by-eng-orchestrator).

---

## 0. Project agent memory

Each **project** keeps durable agent notes under **`.agents/memory/`** (commit to git). Cursor resolves the same content via `.cursor/agent-memory/` symlink.

| Path | Purpose |
|------|---------|
| `_project/MEMORY.md` | Shared stack, conventions, links (≤200 lines) |
| `_project/specs-index.md` | REQ / ARCH / BUG status table |
| `<agent-name>/MEMORY.md` | Per-role learnings (e.g. `backend-engineer/`) |
| `<agent-name>/<topic>.md` | Detailed notes linked from MEMORY.md |

**Flow:** read `_project` + your agent folder **at start**; update **at end** (skill: `spec-agent-memory`).  
Every agent file wires **`spec-agent-memory`** and its `.agents/memory/<agent>/` path. Bootstrap creates stubs via `scripts/bootstrap-agent-memory.sh`.  
Cursor `sessionStart` injects a short `_project/MEMORY.md` summary (≤30 useful lines) when present.  
Template: `SPECFORGE_HOME/templates/spec-driven-app/agents-overlay/memory/`  
Rule (in template): `.cursor/rules/agent-memory.mdc` (`alwaysApply: true`).

Memory **indexes** `.specs/` — it does not replace specs as source of truth. Never store secrets.

---

## 1. Core Principles

| # | Principle | Meaning |
|---|-----------|---------|
| 1 | **Spec before code** | Every code change must be traceable to a spec change. Code is a consequence of specs, not the source of truth. |
| 2 | **Specs are the source of truth** | Agents read `.specs/` first, always. Not chat history, not prior agent summaries. |
| 3 | **Independent epistemics** | Every agent forms its own judgment from primary sources. No agent validates another agent's conclusion — it validates against the spec. |
| 4 | **Mandatory challenge + human stop** | When the recipe requires it, no REQ/ARCH is `APPROVED` without challenger output **and** a **human** approve/override/defer. Max 2 challenge rounds; no author↔challenger duel. |
| 5 | **Verifier reads specs + cited evidence, not the chain** | Verifier is epistemically isolated from implementer/reviewer prose. It consumes orchestrator inputs only: APPROVED REQ (and BUG when in scope), git SHA, Gate 3 test report, waiver ledger, optional ARCH path — then the codebase. |
| 6 | **Minimal context, maximum signal** | Agents receive only what they need. Large outputs stay in subagent context or are compressed before returning to parent. |
| 7 | **Right-size the ceremony** | Start with the smallest agent/spec footprint that protects the work. Add roles and gates only when complexity or risk justifies them. |
| 8 | **Ephemeral chat, durable specs** | Conversation is not source of truth. After each gate, persist state to `.specs/` and `.agents/memory/` (Cursor: `.cursor/agent-memory/`). Next agent gets **file paths + recipe/phase only**—not prior agent narratives. |
| 9 | **Stack from specs/repo, not vendor defaults** | Agents must not bind to cloud-vendor skills by default. Match ARCH/repo toolchain; vendor skills only when explicitly in scope. |

---

## 2. Spec-Driven Model

### Complexity tiers

The full pipeline below is the **maximum rigor model**, not the default for every task.

| Tier | Use when | Agent footprint | Spec footprint |
|------|----------|-----------------|----------------|
| **Tier 0 — Spike** | Throwaway prototype or research | Main Agent (or deprecated `tech-lead` spike note only) | `.specs/spikes/SPIKE-NNN.md` optional; no fake APPROVED |
| **Tier 1 — Small app** | MVP, solo/low-risk app | `eng-orchestrator`, `requirements-analyst`, implementer, `test-runner`, `verifier` | REQ only; ARCH optional |
| **Tier 2 — Productized app** | Real users, releases, recurring bugs | Add `architect`, `challenger`, reviewers, `spec-guardian` | REQ + ARCH + ADR for major choices |
| **Tier 3 — Enterprise / regulated** | PII, auth, payments, infra, multi-team | Full agent team | Full `.specs/` tree, contracts, test plans, ADRs |

### Promotion triggers

Move up a tier when any of these appear:

- More than one long-lived feature area
- Public API, auth, payments, PII, or external integrations
- More than one deployable service or platform environment
- Repeated bugs caused by unclear requirements or architecture
- Another agent or engineer must resume work from durable context

### Tier 1 minimum viable flow

For small projects, use:

```
eng-orchestrator → requirements-analyst → [challenger if consequential] → **user APPROVED**
  → implementer(s) → test-runner → [code-reviewer as needed] → verifier
```

Use `challenger` for consequential requirement approvals (human still sets `APPROVED`). Add `architect` when the change crosses a durable boundary: schema, public API, security, deployment, or framework choice. Never use `tech-lead` for production recipes.

---

### The lifecycle — requirements drive everything

**Build from recipes §0 matrix (minimal first).** Full team below is a **Tier 2–3 ceiling reference**, not the default. **User** owns every `APPROVED` and every override.

### Prefer these minimal plans

```
Capability Tier 1:
  requirements-analyst → **user APPROVED** → implementer → test-runner → verifier

Bug-fix Tier 1:
  debugger (BUG) → implementer → test-runner → code-reviewer → verifier

Hotfix (urgent only):
  debugger → implementer → test-runner → verifier  (+ security if adjacent; review ≤48h if deferred)
```

### Ceiling reference only (`greenfield-feature` / `capability`, Tier 2–3)

```
Human intent
     │
     ▼
requirements-analyst  ──→  REQ (DRAFT) → challenger R1 → author resolve → **Human APPROVED**
     ▼
architect             ──→  ARCH (DRAFT) → challenger R1 → **Human APPROVED**  [when ARCH required]
     │
     ├─ backend / frontend / fullstack* / mobile / data  (route by surface)
     ▼
qa-engineer → test-runner → code-reviewer ∥ security-reviewer → verifier → spec-guardian
     ▼
DONE
```

`*` Prefer split backend ∥ frontend when the slice is large or contracts are still moving. Add O agents only when the need checklist flags risk.

**Infra:** `architect` → human → `platform-engineer` and/or `sre-devops` per matrix.
### Golden rule for every agent

> You are NOT a validator of the work you receive.
> You are an independent expert who reads primary sources
> (specs, code, tests) and forms your own judgment.
> If any prior agent's conclusion contradicts what you find,
> you report the discrepancy — you never reconcile it silently.

---

## 3. Spec File Structure

Every project that uses this agent team **must** have this structure:

```
.specs/
├── requirements/
│   ├── REQ-001-feature-name.md       ← User stories + acceptance criteria
│   └── REQ-002-another-feature.md
├── architecture/
│   ├── ARCH-000-system-overview.md   ← System-level design, boundaries
│   └── ARCH-001-feature-name.md      ← Feature-level architecture
├── decisions/
│   ├── ADR-001-database-choice.md    ← Architecture Decision Records (immutable)
│   └── ADR-002-event-sourcing.md     ← Supersede with new ADR, never edit old
├── contracts/
│   ├── api/
│   │   └── openapi.yaml              ← REST / GraphQL contracts (or project equivalent)
│   ├── events/
│   │   └── schema.md                 ← Queue / event contracts
│   └── data/
│       └── models.md                 ← Canonical data model
├── test-plans/
│   └── TP-001-feature-name.md        ← QA test plan, derived from REQ not impl
├── maintenance/
│   └── BUG-001-short-title.md        ← Defect diagnosis (debugger); parent REQ link
├── spikes/
│   └── SPIKE-001-short-title.md      ← Tier 0 spike notes (promote to REQ/ARCH)
├── handoffs/
│   ├── GATE-REQ-001-approved.md      ← Optional checkpoint files (see §5)
│   └── test-reports/                 ← Durable Gate 3 evidence (recommended)
└── CHANGELOG.md                      ← Agent-maintained; what changed and why
```

### REQ file template

```markdown
# REQ-NNN — [Feature Name]
> Status: DRAFT | APPROVED
> Author: requirements-analyst | Date: YYYY-MM-DD | Version: 1.0

## Problem statement
[One paragraph. What user need is unmet, or what constraint is violated.]

## Acceptance criteria
- [ ] Given [context], when [action], then [outcome]
- [ ] Given ...

## Out of scope
- [Explicit exclusions to prevent scope creep]

## Assumptions challenged
- [Assumption from original request] → Resolution: [how it was resolved]

## Objections resolved
- [C1 Blocking] → fixed: [how] | deferred: [why + user ack] | human override: [rationale]

## Open questions
- [Questions blocking approval — clear or defer before user sets APPROVED]
```

### ARCH file template

```markdown
# ARCH-NNN — [Feature Name]
> Status: DRAFT | APPROVED
> Reads: REQ-NNN | Date: YYYY-MM-DD

## Approach
[One paragraph summary of the chosen design.]

## Alternatives considered
| Option | Pros | Cons | Decision |
|--------|------|------|----------|

## Component design
[Diagram or description of components and their relationships.]

## API / data changes
[Links or inline contracts.]

## Failure modes
[What breaks, how it degrades, how it recovers.]

## Security surface
[Auth, authz, PII, trust boundaries.]

## Infra / ops impact
[New services, scaling, migrations, env vars.]

## Objections resolved
- [C1 Blocking] → fixed: [how / ADR] | deferred: [why] | human override: [rationale]
```

### ADR file template

```markdown
# ADR-NNN — [Decision title]
> Date: YYYY-MM-DD | Status: Accepted | Supersedes: —

## Context
[Why this decision was needed. Include challenge round / human decision if applicable.]

## Decision
[What was decided.]

## Consequences
[What becomes easier, harder, or impossible as a result.]

## Alternatives rejected
[Options not chosen and the reason.]

## Challenger IDs addressed
- C1 → fixed in spec | overridden by human: [rationale] | deferred: [why]

## Deferred risks
- [Residual Important items accepted by human]
```

### BUG file template (`bug-fix` / `hotfix`)

```markdown
# BUG-NNN — [title]
> Status: OPEN | FIXED
> Parent REQ: REQ-NNN
> Severity: critical | high | medium | low

## Observed behavior
## Expected behavior (from REQ acceptance criterion if applicable)
## Reproduction
## Root cause (filled by debugger)
## Fix scope / proposal
## Spec gap? (yes/no)
## Regression tests required
```
---

## 4. Agent Roster

All agents live in `SPECFORGE_HOME/agents/` (user-scope, all projects).

### Leadership & orchestration

| Agent | File | Role | Readonly |
|-------|------|------|----------|
| `eng-orchestrator` | `eng-orchestrator.md` | Recipe×tier plan; enforces gates; checkpoints; does not author/approve/waive | No |
| `tech-lead` | `tech-lead.md` | **Deprecated** for recipes — Tier 0 spike note only; else redirect to orchestrator | No |

### Spec agents

| Agent | File | Role | Readonly |
|-------|------|------|----------|
| `requirements-analyst` | `requirements-analyst.md` | Writes testable REQ (DRAFT); user sets APPROVED after challenger | No (writes specs) |
| `architect` | `architect.md` | Produces ARCH + ADRs + contracts from APPROVED REQ; user sets ARCH APPROVED | No (writes specs) |
| `challenger` | `challenger.md` | Adversary; ≤2 rounds then human approve/override; prevents author loops | Yes |
| `spec-guardian` | `spec-guardian.md` | Gate 4 drift; Blocking vs advisory; ≤2 audits then human waive | Yes |
| `adr-recorder` | `adr-recorder.md` | Immutable ADRs including overrides/deferrals; does not start challenge loops | No (writes ADRs) |

### Implementation agents

Gates are **recipe × tier** (see each agent file and `eng-orchestrator`): REQ `APPROVED` always; ARCH when required. Implementers propose contract diffs — they do not approve specs or replace `verifier`.

| Agent | File | Role | Readonly |
|-------|------|------|----------|
| `backend-engineer` | `backend-engineer.md` | API/server — prefer when API/data-only | No |
| `frontend-engineer` | `frontend-engineer.md` | UI-only when contracts frozen; match repo stack | No |
| `fullstack-engineer` | `fullstack-engineer.md` | Small vertical slice only; split if large | No |
| `mobile-engineer` | `mobile-engineer.md` | iOS/Android/RN/Flutter — platform + offline/permissions | No |
| `data-engineer` | `data-engineer.md` | Schemas/migrations/ETL — recipe×tier gates; propose data contracts | No |

### Quality & safety agents

| Agent | File | Role | Readonly |
|-------|------|------|----------|
| `qa-engineer` | `qa-engineer.md` | Test strategy from APPROVED REQ → TP file (writes `.specs/test-plans/`) | No |
| `test-runner` | `test-runner.md` | Run tests; capped fixes; durable Gate 3 evidence (not verifier) | No |
| `code-reviewer` | `code-reviewer.md` | Spec/contract review; Critical blocks Gate 3; ≤2 rounds then human | Yes |
| `security-reviewer` | `security-reviewer.md` | Security audit; Critical blocks Gate 3; ≤2 rounds then human | Yes |
| `verifier` | `verifier.md` | Readonly; REQ/BUG + SHA + test report only; criterion evidence | Yes |
| `debugger` | `debugger.md` | BUG-NNN + root cause; diagnose-first; spec-gap stop | No |

### Platform agents

| Agent | File | Role | Readonly |
|-------|------|------|----------|
| `platform-engineer` | `platform-engineer.md` | IaC modules/resources; plan/validate evidence; prod apply only if user asks | No |
| `sre-devops` | `sre-devops.md` | CI/CD + observability; no default vendor skills; split vs platform | No |

---

## 5. Pipeline & Handoff Protocol

### HANDOFF block (mandatory at end of every agent output)

Authoritative schema: skill **`spec-handoff`**. Every phase end **must** include:

```markdown
---
## HANDOFF
**Goal completed:** [one line]

**Artifacts written:**
- [file paths]

**Key decisions:**
- [max 5 bullets]

**For next agent — paste into their prompt:**
- Spec files to read: [paths]
- Constraints: [hard constraints]
- Open risks: [unresolved items]

**Blockers:** [none | list]

**Memory updated:**
- [.agents/memory/ or .cursor/agent-memory/ paths]

**Checkpoint file:**
- [.specs/handoffs/GATE-*.md or "none"]

**Token profile:** [advisory | handoff | implement | docs-touch | release]

**Read order (next agent):** [max 3 paths — do not re-read chat]

**Do not carry forward:** [what is now only on disk]
---
```

Orchestrator also tracks: **Recipe**, **Tier**, **Phase**, **Next agent**, **Gate evidence paths** (SHA, test report, finding IDs). Delegation prompts stay **path-only** — do not paste this HANDOFF prose wholesale into the next subagent.

### Approval authority (human-gated)

| Action | Who |
|--------|-----|
| Write/edit DRAFT specs | Phase owner (`requirements-analyst`, `architect`, `debugger`, `adr-recorder`) |
| Raise objections / review findings | `challenger`, `code-reviewer`, `security-reviewer`, `spec-guardian` |
| Resolve objections in the artifact | Phase owner (cite each ID) |
| Set `Status: APPROVED` | **User only** |
| Override / defer Blocking / waive Critical / waive Blocking drift | **User only** — record in spec, ADR, or checkpoint |
| Propose contract diffs | Implementers — freeze/accept via architect + user when consequential |
| Mark DONE | Orchestrator after Gate 4 evidence |

Agents must not self-approve DRAFT→APPROVED.

### Challenge / review / drift anti-loops

| Loop | Cap | Round 2 | Deadlock |
|------|-----|---------|----------|
| Challenger ↔ author | **2** rounds/artifact/phase | Delta only (open Blocking / regressions) | Human override or reject — **no Round 3** |
| Code/security reviewer ↔ implementer | **2** rounds | Delta only | Human waive or reject |
| Spec-guardian ↔ fix | **2** audits | Delta only | Human waive Blocking drift |
| Implementer ↔ test-runner | **2** fix loops | — | Escalate to user |

**Challenge flow:** Author DRAFT → Challenger R1 → Author resolves → **present to user** → approve | override | send back → optional R2 → user decision.

Severity for challenger: **Blocking** / **Important** / **Nit** (only Blocking holds APPROVED).  
Reviewers: only **Critical** holds Gate 3.  
Guardian: only **Blocking** drift holds DONE; **Advisory** does not.

### Implementer routing (quick)

| Situation | Owner |
|-----------|--------|
| UI-only, API frozen | `frontend-engineer` |
| API/server-only | `backend-engineer` |
| Canonical model / ETL / migrations | `data-engineer` |
| Mobile client | `mobile-engineer` |
| Small API+UI slice, contracts frozen | `fullstack-engineer` |
| Large / contracts moving | Split; freeze contracts first |
| IaC modules | `platform-engineer` |
| CI/CD / alerts / deploy wiring | `sre-devops` |
### Checkpoint and reset policy (Principle 8)

Chat is **ephemeral**. Specs and memory are **durable**. The orchestrator must **checkpoint before reset**—never clear or abandon context until files on disk are updated.

#### Persist before any reset

| Artifact | Required when |
|----------|----------------|
| Updated REQ/ARCH/BUG/ADR | Spec content changed |
| `.cursor/agent-memory/_project/specs-index.md` | Any spec status change |
| `.cursor/agent-memory/eng-orchestrator/MEMORY.md` | Recipe, phase, blockers, next agent |
| `.specs/handoffs/GATE-<phase>.md` | Recommended at every gate boundary (optional for tiny Tier 1 tasks) |
| Contracts under `.specs/contracts/` | API or data model changed |

#### When to start a **fresh subagent** (default at gate boundaries)

| After gate | Next invocation |
|------------|-----------------|
| REQ APPROVED | New `architect` (or implementer at Tier 1)—prompt = REQ path only |
| ARCH APPROVED | New implementer(s)—prompt = REQ + ARCH paths only |
| Implement complete | New `test-runner`, then new `verifier` |
| Verifier pass | New `spec-guardian` if Tier 2+; update memory |

**Do not** `resume` a subagent across gate boundaries except continuing the **same** in-flight task (e.g. debugger mid-incident).

#### When to start a **new parent Agent chat**

Recommend a new chat when:

- A REQ or major phase is **DONE**
- Parent context is long (rough guide: >30 turns or repeated re-explaining)
- Switching recipe (`bug-fix` → `greenfield-feature`)

Seed the new chat with:

```
Recipe: [id] | Tier: [0-3] | Phase: [next]
Read: .cursor/agent-memory/_project/specs-index.md
Read: [spec paths only]
Do not rely on prior chat summaries.
```

#### Delegation prompt limits (orchestrator)

- **≤500 words** per subagent delegation
- **Mostly file paths**, recipe, tier, phase, blockers
- **Never paste** prior subagent prose, tool logs, or HANDOFF narratives—only paths

#### When **not** to reset

- Mid-debug (`debugger`) until BUG-NNN or reproduction steps are written
- Mid-implement with uncommitted decisions not in spec or ADR
- `hotfix` until BUG/CHANGELOG backfill policy is satisfied (see recipes)

#### Checkpoint file template (`.specs/handoffs/GATE-<slug>.md`)

```markdown
# Checkpoint — [phase name]
> Date: YYYY-MM-DD | Recipe: [id] | Tier: [0-3]

## Phase completed

## Spec files (source of truth)
- 

## Orchestrator state
- **Next agent:**
- **Blockers:**

## Do not carry forward in chat
- [decisions now captured in specs/memory only]
```

### Orchestrator gates (enforced by `eng-orchestrator`)

Gates are **recipe × tier**. Authoritative R/O/— table: `ENGINEERING-RECIPES.md` §0. Summary for capability recipes (`new-application`, `greenfield-feature`):

```
Gate 1: Before architect (or Tier 1 implementer when ARCH is skipped)
  → REQ-NNN.md must have Status: APPROVED (user)
  → challenger objections resolved when challenger ran (optional at Tier 1 unless consequential)

Gate 2: Before any implementer runs
  → If ARCH required (Tier 2–3 always; Tier 1 when schema/API/security/deploy/framework crossed):
      ARCH-NNN.md Status: APPROVED (user) + challenger objections resolved
  → Else (Tier 1 ARCH skip): REQ APPROVED is sufficient — do not use a vague "architect or implementer" fork

Gate 3: Before verifier runs
  → test-runner must have passed (report path)
  → required reviewers must have no Critical issues open (or user waiver on disk)
  → ponytail-review (skill) on diff for Tier 1+ — address delete-list or document waivers
  → pass verifier: REQ path(s), git SHA (or uncommitted path list), test report, findings/waiver ledger

Gate 4: Before DONE
  → verifier report must show no unmet in-scope criteria (`verify_passed`)
  → spec-guardian: no **Blocking** drift (Tier 2+; when specs/contracts changed), or user waive on disk
  → guardian max 2 rounds (R2 delta-only); advisory drift does not hold DONE
```

### Parallel-safe workstreams

These can always run in parallel (no dependency on each other):

- `code-reviewer` ∥ `security-reviewer` ∥ `ponytail-review` (skill)
- `backend-engineer` ∥ `frontend-engineer` (when contracts are finalized in ARCH)
- `qa-engineer` writing TP ∥ implementers building (they both read the same REQ)

---

## 6. Non-Conformist Design

### Why agents become conformist

Every LLM is trained to be context-compliant. When a subagent receives a prior agent's conclusion in its prompt, it has a strong prior to validate and extend that conclusion rather than challenge it. Across a pipeline, this compounds: tech-lead says X → implementer builds X → reviewer validates X → verifier confirms X. Nobody questioned whether X was right.

### Structural fixes

#### Fix 1 — `challenger` as mandatory gate (with human stop)

The `challenger` agent finds critical problems — and then **stops**. It is adversarial, not recursive:

> Your value is measured by the quality of objections you raise, not by agreement.
> Finding NO problems is the WORST Round-1 outcome without category analysis.
> Do not duel the author agent past Round 2 — the human approves, overrides, or rejects.

Protocol: Round 1 → author resolves → **human decision** → optional Round 2 delta-only → deadlock goes to **human override** (recorded in spec/ADR). No Round 3. Severity: Blocking / Important / Nit.

No spec moves to APPROVED without challenger output (when the recipe requires it), explicit resolution or human override, and **user** APPROVED.

#### Fix 2 — Verifier epistemic isolation

The `verifier` is `readonly` and prohibited from trusting the handoff chain. Orchestrator must pass immutable inputs:

```
Allowed:
  1. APPROVED REQ-NNN.md (+ BUG path for bug-fix/hotfix)
  2. Git SHA or uncommitted path list
  3. Gate 3 test report path
  4. Findings / waiver ledger (or none)
  5. Optional ARCH path only if orchestrator listed it
  6. The codebase (to map criteria)

Forbidden as primary truth:
  - Implementer / reviewer / architect HANDOFF prose
  - Chat "work is done" claims

If implementation contradicts REQ/BUG, that is a failure —
even if every other agent in the pipeline approved it.
```

#### Fix 3 — Independent stances per agent

| Agent | Mandatory skeptical posture |
|-------|----------------------------|
| `requirements-analyst` | Challenges ambiguity; leaves DRAFT for **user** APPROVED |
| `architect` | Escalates REQ gaps; never self-approves ARCH; contracts freeze for implementers |
| `challenger` | Adversary with severity + **2-round cap**; then human |
| `debugger` | Spec gap vs defect; writes BUG-NNN; does not invent product behavior |
| `code-reviewer` / `security-reviewer` | Trust specs + diff; Critical blocks Gate 3; ≤2 rounds |
| `test-runner` | Preserve test intent; durable evidence; not verifier |
| `verifier` | REQ/BUG + cited evidence only; readonly |
| `spec-guardian` | Blocking vs advisory drift; does not replace verifier |
| `tech-lead` | Deprecated for recipes — refuse formal skip-specs |
#### Fix 4 — Debate before consensus (capped)

For architectural decisions:
1. `architect` proposes → writes ARCH (draft)
2. `challenger` Round 1 → returns severity-tagged objections
3. `architect` resolves each ID in the ARCH doc; major resolutions → `adr-recorder`
4. **Human** sees the table: approve, override (with rationale), defer Important, or send back
5. Optional `challenger` Round 2 (delta only) if human requested re-check
6. ARCH `APPROVED` only by **human** — never by agent stalemate resolution

This creates an audit trail of rejected alternatives and overrides without an infinite author↔challenger loop.

#### Fix 5 — Checkpoint and reset (anti–context rot)

Long shared chat is a conformist amplifier. After each gate:

1. Write state to `.specs/`, `specs-index.md`, orchestrator memory, and optionally `.specs/handoffs/`
2. Delegate to a **new** subagent with paths only (Principle 8)
3. Do not resume implementer → verifier in the same biased thread

The verifier and challenger are most effective when they **cannot** see the implementer's narrative.

---

## 7. Token Efficiency Strategy

### What Cursor does automatically (no config)

| Mechanism | Token saving |
|-----------|-------------|
| **Explore subagent** | Runs many parallel searches with a faster model; parent gets only relevant findings |
| **Bash subagent** | Verbose shell output stays isolated; parent gets summary |
| **Browser subagent** | DOM noise (10K–135K tokens) stays in subagent context |
| **Codebase vector index** | Semantic retrieval fetches only relevant chunks, not whole files |
| **Instant Grep** | Exact symbol matches skip embedding model entirely |

### What `context-mode` provides (already installed, auto-active)

The `context-mode` plugin is installed at `~/.claude/plugins/cache/` and wired via a `PreToolUse` hook — meaning **all subagents in your team automatically use it**.

| Tool | What it does | Typical saving |
|------|-------------|----------------|
| `ctx_execute` | Runs CLI commands in sandbox; only summary enters context | ~90% on verbose CLIs |
| `ctx_execute_file` | Analyzes large files in sandbox; only findings enter context | ~95% on log/data files |
| `ctx_fetch_and_index` + `ctx_search` | Indexes docs server-side; BM25 search returns only relevant chunks | ~99% vs raw page fetch |
| Playwright + `filename` → `ctx_index(path)` | DOM snapshots isolated to file; search returns relevant parts | ~99% (270K → ~430B) |

**No action needed** — the PreToolUse hook injects routing for all agents.

### What you control via agent config

#### Model tiering by reasoning requirement

```yaml
# Assign fast/cheap models to read-heavy, structured-output agents:
model: composer-2

# Apply to:
#   requirements-analyst   (reads request, writes structured REQ)
#   spec-guardian          (reads specs + code, compares)
#   test-runner            (runs commands, reports)
#   code-reviewer          (reads diff, structured report)

# Keep inherit (full model) for:
#   challenger             (adversarial reasoning quality matters)
#   architect              (architectural decisions)
#   security-reviewer      (security reasoning quality matters)
#   verifier               (independent judgment quality matters)
```

#### Keep agent prompts under ~400 words

Every word in a system prompt is charged on **every turn** of that subagent. Long prompts dilute focus and increase cost. The agents in `SPECFORGE_HOME/agents/` are already sized correctly.

#### Use skills for one-shot tasks

A skill has no subagent context window overhead. Use it instead of a subagent when:
- Task completes in one shot (format imports, generate changelog)
- No context isolation is needed
- No follow-up turns are expected

#### `.cursorignore` for generated files

Keeping large generated files out of the codebase index keeps semantic search precise:

```
# .cursorignore (add to project root)
dist/
build/
node_modules/
*.lock
coverage/
.nyc_output/
__pycache__/
*.egg-info/
.terraform/
*.tfstate
*.tfstate.backup
```

> **Note:** Do NOT ignore `.specs/` — agents must be able to read spec files via semantic search.

### Spec files as the primary context source

The biggest token saving in the spec-driven model is structural:

- **Without specs:** orchestrator summarizes multi-turn conversation history into each agent prompt → 10KB+ context injection per agent
- **With specs:** orchestrator gives each agent a file path to read → `REQ-NNN.md` at 1–3KB, read via codebase index → 70–90% reduction in handoff context

This is why **specs as source of truth** is a token efficiency strategy as much as a correctness strategy.

**Principle 8 (checkpoint + reset):** After each gate, persist to disk then delegate with paths only. Avoid resuming subagents across gates. Start a new parent chat per REQ or when context rots. See §5 Checkpoint and reset policy.

### Parallel vs sequential token math

| Strategy | Wall time | Total tokens |
|----------|-----------|-------------|
| Sequential `code-reviewer` then `security-reviewer` | 2x latency | Same total |
| Parallel `code-reviewer` ∥ `security-reviewer` | 1x latency | Same total |

Parallel saves **wall time, not tokens**. Run parallel when outputs are independent.

### Measuring tokens & release efficiency

Exact per-subagent metering is **not available in hooks today**. Use three tiers (see **`SPECFORGE_HOME/ENGINEERING-METRICS.md`**):

| Tier | Source |
|------|--------|
| A | Billing export (ground truth) |
| B | `session.jsonl` ledger (hooks) + `ctx stats` + gate file counts |
| C | `bash scripts/estimate-pipeline-tokens.sh <recipe> --tier N --mode minimal` (ceiling optional) |

At release (Tier 2+): `bash scripts/collect-release-metrics.sh --since <tag>` → skill **`spec-release-metrics`** → `.specs/metrics/releases/REL-*.yaml`.

Track **tokens/REQ** together with verifier gaps and spec drift — never optimize tokens alone.

### Token discipline (harness)

Skills: `spec-advisory`, `spec-token-budget`, `spec-vendor-sync`. Rule: `rules/token-discipline.mdc`.

| Hook | Behavior |
|------|----------|
| `beforeSubmitPrompt` | Detect advisory / docs / vendor intent → inject readonly + budget |
| `subagentStop` | Checkpoint + compress HANDOFF reminder |
| `sessionStop` | Suggest `distill-learning-journal.sh` |

Meta recipes: `advisory-only`, `vendor-sync`, `docs-touch` — see ENGINEERING-RECIPES.md.

## 8. Rules for Future Agents

When adding new agents to this team, enforce these rules:

### Mandatory in every agent prompt

```
1. Read the relevant .specs/ files before doing any work.
   Never rely on the conversation summary or handoff notes as your
   primary source of truth — they may contain prior agent drift.

2. End every output with the HANDOFF block (see section 5).

3. Report divergence between what you find and what you were told.
   Do not silently reconcile discrepancies.

4. At gate boundaries, ensure orchestrator updates specs-index and memory;
   next agent receives file paths only (Principle 8).
```

### Mandatory in every agent frontmatter

```yaml
---
name: agent-name           # lowercase, hyphenated
description: >-            # specific enough for auto-delegation
  [What it does]. Use when [precise trigger condition].
  [Optional: "Use proactively when..." for automatic invocation]
model: inherit             # or composer-2 for read-heavy agents
readonly: true/false       # true for all review/analysis agents
is_background: false       # true only for genuinely long-running scans
---
```

### Agent naming conventions

| Prefix | Category | Examples |
|--------|----------|---------|
| (none) | Implementation | `backend-engineer`, `frontend-engineer`, `fullstack-engineer`, `mobile-engineer`, `data-engineer` |
| (none) | Platform | `platform-engineer`, `sre-devops` |
| (none) | Quality | `qa-engineer`, `test-runner`, `verifier`, `debugger` |
| (none) | Spec | `requirements-analyst`, `architect`, `challenger`, `adr-recorder` |
| (none) | Review | `code-reviewer`, `security-reviewer`, `spec-guardian` |
| (none) | Orchestration | `eng-orchestrator` (`tech-lead` deprecated) |

### Do not add agents for:
- Single-purpose one-shot tasks (use a **skill** instead)
- Generic "helper" agents with vague descriptions
- Tasks the main agent handles in under 3 tool calls

---

## Appendix A — Semantic Caching (external gateway pattern)

Cursor has **no built-in semantic caching** of LLM responses. This is a gateway-layer feature.

If you build **SDK-driven or Cloud Agent workflows** (Cursor SDK → external API), semantic caching can be layered via:

| Tool | Notes |
|------|-------|
| **Azure APIM AI Gateway** | Semantic cache for Azure-hosted models; use `azure-aigateway` skill |
| **Portkey / LangSmith** | Prompt-level semantic dedup + analytics |
| **OpenAI / Anthropic prefix caching** | Exact prefix match (not semantic); free on long system prompts |

For in-IDE Cursor agent workflows, token efficiency comes from the strategies in Section 7, not response caching.

---

## Appendix D — Orchestrator recipes (production + meta)

Full definitions: `SPECFORGE_HOME/ENGINEERING-RECIPES.md`

| Recipe | Use |
|--------|-----|
| `greenfield-feature` | New user-facing capability (`capability` / `feature-change` alias); tier-scaled minimal plan — not a default |
| `new-application` | Greenfield product; ARCH-000 if T2+ or durable boundary |
| `bug-fix` | Defect — `.specs/maintenance/BUG-NNN.md` + parent REQ |
| `hotfix` | Urgent fix; backfill BUG/CHANGELOG after |
| `maintenance` | Deps, refactor — ADR / ARCH delta |
| `infra-change` | Platform (IaC) + SRE (CI/CD/observability) |
| `spec-only` | REQ/ARCH without code |
| `security-patch` | CVE / security findings |
| `advisory-only` | Review/feasibility — **readonly** until user says implement |
| `vendor-sync` | Sync third-party skills (harness only) |
| `docs-touch` | README/ROADMAP/docs only |

Invoke: `/eng-orchestrator recipe: bug-fix — [description]` or skill `/spec-recipes`.

Authoritative gate matrix, failure transitions, and verifier inputs: `agents/eng-orchestrator.md`.

---

## Appendix C — Spec skills (installed)

| Skill | Path | Agent(s) |
|-------|------|----------|
| `spec-req-author` | `SPECFORGE_HOME/skills/spec-req-author/` | requirements-analyst |
| `spec-arch-author` | `SPECFORGE_HOME/skills/spec-arch-author/` | architect, adr-recorder (ADR template); implementers only to spot gaps |
| `spec-challenger` | `SPECFORGE_HOME/skills/spec-challenger/` | challenger (capped rounds + human stop) |
| `spec-handoff` | `SPECFORGE_HOME/skills/spec-handoff/` | all agents (end of phase) |
| `spec-verifier` | `SPECFORGE_HOME/skills/spec-verifier/` | verifier (not test-runner) |
| `spec-guardian-drift` | `SPECFORGE_HOME/skills/spec-guardian-drift/` | spec-guardian |
| `spec-pipeline` | `SPECFORGE_HOME/skills/spec-pipeline/` | eng-orchestrator |
| `spec-recipes` | `SPECFORGE_HOME/skills/spec-recipes/` | eng-orchestrator |
| `spec-agent-memory` | `SPECFORGE_HOME/skills/spec-agent-memory/` | all agents |
| `spec-advisory` | `SPECFORGE_HOME/skills/spec-advisory/` | advisory-only / review prompts |
| `spec-token-budget` | `SPECFORGE_HOME/skills/spec-token-budget/` | eng-orchestrator + meta recipes |
| `spec-vendor-sync` | `SPECFORGE_HOME/skills/spec-vendor-sync/` | vendor-sync recipe |
| `spec-release-metrics` | `SPECFORGE_HOME/skills/spec-release-metrics/` | release metering (Tier 2+) |

### Ponytail skills (vendored, MIT)

Upstream: [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) · refresh: `bash scripts/sync-ponytail.sh`

| Skill | Path | Agent(s) |
|-------|------|----------|
| `ponytail` | `SPECFORGE_HOME/skills/ponytail/` | implementers: backend, frontend, fullstack, mobile, data, platform, sre, debugger, test-adjacent minimal fixes |
| `ponytail-review` | `SPECFORGE_HOME/skills/ponytail-review/` | code-reviewer (Gate 3) |
| `ponytail-audit` | `SPECFORGE_HOME/skills/ponytail-audit/` | maintenance recipe |
| `ponytail-debt` | `SPECFORGE_HOME/skills/ponytail-debt/` | maintenance recipe |

Cursor: always-on rule `SPECFORGE_HOME/rules/ponytail.mdc` (bootstrapped to `.cursor/rules/`).

Do **not** default security/SRE/platform agents to cloud-vendor skills; match ARCH/repo (Principle 9).
---

## Appendix B — Quick reference: invoke the team

```
# Orchestrated capability (need check first; minimal plan from recipes matrix)
/eng-orchestrator Tier: 1 | need: new settings capability
Add user profile API with React settings page

# Advisory (readonly)
/eng-orchestrator recipe: advisory-only — should we add ForgeCode support?

# Spec phase only
/requirements-analyst Define requirements for the notification system
/challenger Review .specs/requirements/REQ-001.md  (Challenge round: 1)

# Implement against existing approved specs
/backend-engineer Implement REQ-001; read REQ + ARCH paths from orchestrator
/frontend-engineer Build UI per REQ-001 (contracts frozen)
/debugger bug-fix — capture BUG-NNN then hand off

# Quality
/qa-engineer Write TP for APPROVED REQ-001
/test-runner Run TP-mapped suite; save report path
/code-reviewer Review round: 1 — diff vs REQ/contracts
/security-reviewer Review auth/PII surface (specs first; no vendor default)

# Verify + drift
/verifier Confirm REQ-001; inputs: SHA + test report + waivers
/spec-guardian Blocking vs advisory drift before DONE

# Platform
/platform-engineer IaC modules per ARCH infra (plan/validate evidence)
/sre-devops Wire CI/CD + alerts per ARCH (repo toolchain; no vendor default)
```

---

*This playbook is maintained with the agent team. Any change to agent behaviour, pipeline gates, or spec format must update this document and the matching `agents/*.md` contracts.*