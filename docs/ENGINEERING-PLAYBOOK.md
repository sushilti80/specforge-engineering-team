# Engineering Team Playbook
> Spec-driven agentic engineering · Non-conformist design · Token efficiency
>
> Last updated: 2026-05-18 | **Bootstrap:** `~/.cursor/BOOTSTRAP-SPEC-DRIVEN-PROJECT.md` | Agents: `~/.cursor/agents/` | Spec skills: `~/.cursor/skills/spec-*/` | Template: `~/.cursor/templates/spec-driven-app/`

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

---

## 0. Project agent memory

Each **project** keeps durable agent notes under **`.cursor/agent-memory/`** (commit to git).

| Path | Purpose |
|------|---------|
| `_project/MEMORY.md` | Shared stack, conventions, links (≤200 lines) |
| `_project/specs-index.md` | REQ / ARCH / BUG status table |
| `<agent-name>/MEMORY.md` | Per-role learnings (e.g. `backend-engineer/`) |
| `<agent-name>/<topic>.md` | Detailed notes linked from MEMORY.md |

**Flow:** read `_project` + your agent folder **at start**; update **at end** (skill: `spec-agent-memory`).  
Template: `~/.cursor/templates/spec-driven-app/.cursor/agent-memory/`  
Rule (in template): `.cursor/rules/agent-memory.mdc` (`alwaysApply: true`).

Memory **indexes** `.specs/` — it does not replace specs as source of truth. Never store secrets.

---

## 1. Core Principles

| # | Principle | Meaning |
|---|-----------|---------|
| 1 | **Spec before code** | Every code change must be traceable to a spec change. Code is a consequence of specs, not the source of truth. |
| 2 | **Specs are the source of truth** | Agents read `.specs/` first, always. Not chat history, not prior agent summaries. |
| 3 | **Independent epistemics** | Every agent forms its own judgment from primary sources. No agent validates another agent's conclusion — it validates against the spec. |
| 4 | **Mandatory challenge** | No spec (requirements or architectural) is approved without a `challenger` review first. |
| 5 | **Verifier reads the spec, not the chain** | The verifier is epistemically isolated from the pipeline. It reads the original REQ spec and the codebase — nothing else. |
| 6 | **Minimal context, maximum signal** | Agents receive only what they need. Large outputs stay in subagent context or are compressed before returning to parent. |
| 7 | **Right-size the ceremony** | Start with the smallest agent/spec footprint that protects the work. Add roles and gates only when complexity or risk justifies them. |
| 8 | **Ephemeral chat, durable specs** | Conversation is not source of truth. After each gate, persist state to `.specs/` and `.cursor/agent-memory/`. Next agent gets **file paths + recipe/phase only**—not prior agent narratives. |

---

## 2. Spec-Driven Model

### Complexity tiers

The full pipeline below is the **maximum rigor model**, not the default for every task.

| Tier | Use when | Agent footprint | Spec footprint |
|------|----------|-----------------|----------------|
| **Tier 0 — Spike** | Throwaway prototype or research | Main Agent or one implementer | Notes only |
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
eng-orchestrator → requirements-analyst → implementer → test-runner → verifier
```

Use `challenger` manually for important requirement approvals. Add `architect` when the change crosses a durable boundary: schema, public API, security, deployment, or framework choice.

---

### The lifecycle — requirements drive everything

```
Human intent
     │
     ▼
requirements-analyst  ──→  REQ-NNN.md (draft)
     │                      └── challenges assumptions inline
     ▼
challenger            ──→  ≥2 critical objections
     │
     ▼
requirements-analyst  ──→  REQ-NNN.md (APPROVED)  ← resolves objections
     │
     ▼
architect             ──→  ARCH-NNN.md + ADR-NNN.md (draft)
     │                      └── reads only APPROVED REQ-NNN.md
     ▼
challenger            ──→  ≥2 critical objections  (separate invocation)
     │
     ▼
architect             ──→  ARCH-NNN.md (APPROVED)  ← resolves objections
     │
     ├─────────────────────┬────────────────────┐
     ▼                     ▼                    ▼
backend-engineer    frontend-engineer    data-engineer
(reads REQ + ARCH)  (reads REQ + ARCH)  (reads REQ + ARCH)
     │
     ▼
qa-engineer         ──→  TP-NNN.md  (reads REQ-NNN.md, not impl summary)
     │
     ▼
test-runner         ──→  runs, fixes, re-runs
     │
     ├──────────────────────┐
     ▼                      ▼
code-reviewer        security-reviewer    (parallel, readonly)
     │
     ▼
verifier            ──→  reads REQ-NNN.md + codebase only
     │                    never reads handoff chain
     ▼
spec-guardian       ──→  checks .specs/ consistency vs repo
     │
     ▼
DONE (specs + code consistent)
```

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
│   │   └── openapi.yaml              ← REST / GraphQL contracts (machine-readable)
│   ├── events/
│   │   └── schema.md                 ← Queue / event contracts
│   └── data/
│       └── models.md                 ← Canonical data model
├── test-plans/
│   └── TP-001-feature-name.md        ← QA test plan, derived from REQ not impl
├── handoffs/
│   └── GATE-REQ-001-approved.md      ← Optional checkpoint files (see §5)
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

## Open questions
- [Questions blocking approval]
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
- [Challenger objection] → Resolution: [how addressed, or ADR reference]
```

### ADR file template

```markdown
# ADR-NNN — [Decision title]
> Date: YYYY-MM-DD | Status: Accepted | Supersedes: —

## Context
[Why this decision was needed.]

## Decision
[What was decided.]

## Consequences
[What becomes easier, harder, or impossible as a result.]

## Alternatives rejected
[Options not chosen and the reason.]
```

---

## 4. Agent Roster

All agents live in `~/.cursor/agents/` (user-scope, all projects).

### Leadership & orchestration

| Agent | File | Role | Readonly |
|-------|------|------|----------|
| `eng-orchestrator` | `eng-orchestrator.md` | Coordinates pipeline; enforces spec gates; never delegates without APPROVED specs | No |
| `tech-lead` | `tech-lead.md` | Architecture plans from conversation (pre-spec-era; replaced by `architect` in spec-driven flow) | No |

### Spec agents

| Agent | File | Role | Readonly |
|-------|------|------|----------|
| `requirements-analyst` | `requirements-analyst.md` | Turns human intent into precise, testable REQ specs; challenges ambiguity | No (writes specs) |
| `architect` | `architect.md` | Produces ARCH specs + ADRs from APPROVED REQ specs | No (writes specs) |
| `challenger` | `challenger.md` | Mandatory adversary; finds ≥2 objections before any spec is approved | Yes |
| `spec-guardian` | `spec-guardian.md` | Post-change: checks .specs/ consistency vs repo; flags drift | Yes |
| `adr-recorder` | `adr-recorder.md` | Captures mid-pipeline decisions into ADR files | No (writes ADRs) |

### Implementation agents

| Agent | File | Role | Readonly |
|-------|------|------|----------|
| `backend-engineer` | `backend-engineer.md` | APIs, services, DBs — reads REQ + ARCH first | No |
| `frontend-engineer` | `frontend-engineer.md` | React/Vue/Angular — reads REQ + ARCH first | No |
| `fullstack-engineer` | `fullstack-engineer.md` | Vertical slice — reads REQ + ARCH first | No |
| `mobile-engineer` | `mobile-engineer.md` | iOS/Android/RN/Flutter | No |
| `data-engineer` | `data-engineer.md` | SQL, ETL, pipelines, warehouses | No |

### Quality & safety agents

| Agent | File | Role | Readonly |
|-------|------|------|----------|
| `qa-engineer` | `qa-engineer.md` | Test strategy from REQ spec → TP file | Yes |
| `test-runner` | `test-runner.md` | Run tests, fix failures, re-run | No |
| `code-reviewer` | `code-reviewer.md` | Reviews code + checks contracts/ alignment | Yes |
| `security-reviewer` | `security-reviewer.md` | Security audit | Yes |
| `verifier` | `verifier.md` | Reads REQ spec + codebase only; no handoff chain | No |
| `debugger` | `debugger.md` | Root cause analysis | No |

### Platform agents

| Agent | File | Role | Readonly |
|-------|------|------|----------|
| `platform-engineer` | `platform-engineer.md` | Terraform, K8s, cloud IAM/networking | No |
| `sre-devops` | `sre-devops.md` | CI/CD, Docker, observability, deploys | No |

---

## 5. Pipeline & Handoff Protocol

### HANDOFF block (mandatory at end of every agent output)

Every agent that produces output for the next stage **must** end with:

```
---
## HANDOFF
**Goal completed:** [one line]
**Artifacts written:** [file paths, e.g. .specs/requirements/REQ-001.md]
**Key decisions:** [bullet list — max 5]
**For next agent — paste this into their prompt:**
  - Spec files to read: [paths]
  - Constraints: [hard constraints next agent must respect]
  - Open risks: [anything unresolved]
**Blockers:** [anything that must be resolved before continuing]

**Memory updated:** [paths under .cursor/agent-memory/ or "none"]

**Checkpoint file:** [.specs/handoffs/GATE-*.md if written, or "none"]
---
```

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

```
Gate 1: Before architect runs
  → REQ-NNN.md must have Status: APPROVED
  → challenger must have run and objections must be resolved

Gate 2: Before any implementer runs
  → ARCH-NNN.md must have Status: APPROVED
  → challenger must have run (second time) and objections resolved

Gate 3: Before verifier runs
  → test-runner must have passed
  → code-reviewer + security-reviewer must have no Critical issues open

Gate 4: Before DONE
  → verifier report must show no "Incomplete or broken" items
  → spec-guardian must show no drift
```

### Parallel-safe workstreams

These can always run in parallel (no dependency on each other):

- `code-reviewer` ∥ `security-reviewer`
- `backend-engineer` ∥ `frontend-engineer` (when contracts are finalized in ARCH)
- `qa-engineer` writing TP ∥ implementers building (they both read the same REQ)

---

## 6. Non-Conformist Design

### Why agents become conformist

Every LLM is trained to be context-compliant. When a subagent receives a prior agent's conclusion in its prompt, it has a strong prior to validate and extend that conclusion rather than challenge it. Across a pipeline, this compounds: tech-lead says X → implementer builds X → reviewer validates X → verifier confirms X. Nobody questioned whether X was right.

### Structural fixes

#### Fix 1 — `challenger` as mandatory gate

The `challenger` agent has one job: find critical problems. It is wired to be adversarial by design:

> Your value is measured by the quality of objections you raise, not by agreement.
> Finding NO problems is the WORST outcome — it means you did not look hard enough.
> If the spec is solid, document SPECIFICALLY why each potential risk does not apply.

No spec moves to APPROVED status without challenger output and explicit resolution.

#### Fix 2 — Verifier epistemic isolation

The `verifier` is explicitly prohibited from reading the handoff chain:

```
You receive no information from the implementer.
Read only:
  1. .specs/requirements/REQ-NNN.md  (the approved requirement)
  2. The codebase  (actual implementation)
  3. Test output   (actual results)

If the implementation contradicts the requirement, that is a failure —
even if every other agent in the pipeline approved it.
```

#### Fix 3 — Independent stances per agent

| Agent | Mandatory skeptical posture |
|-------|----------------------------|
| `requirements-analyst` | Challenges ambiguity, hidden assumptions, and missing edge cases in the original request |
| `architect` | Challenges feasibility and completeness of requirements before designing |
| `challenger` | Adversary by design; argues against the spec it receives |
| `code-reviewer` | Trusts the spec, not the implementer's description |
| `security-reviewer` | Treats all code as potentially dangerous until proven safe |
| `verifier` | Trusts only the REQ spec; the implementer's claim is unproven until verified |
| `spec-guardian` | Trusts only the spec files; the codebase is suspected of drift until proven consistent |

#### Fix 4 — Debate before consensus

For architectural decisions:
1. `architect` proposes → writes ARCH (draft)
2. `challenger` argues against it → returns ≥2 objections
3. `architect` resolves each objection in the ARCH doc, records major resolutions as ADRs
4. ARCH moves to APPROVED only after objections are explicitly addressed — not dismissed

This creates an **audit trail of why rejected alternatives were rejected**, which is exactly what future maintenance agents need.

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

Every word in a system prompt is charged on **every turn** of that subagent. Long prompts dilute focus and increase cost. The agents in `~/.cursor/agents/` are already sized correctly.

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

---

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
| (none) | Implementation | `backend-engineer`, `frontend-engineer` |
| (none) | Platform | `platform-engineer`, `sre-devops` |
| (none) | Quality | `qa-engineer`, `test-runner`, `verifier` |
| (none) | Spec | `requirements-analyst`, `architect`, `challenger` |
| (none) | Review | `code-reviewer`, `security-reviewer`, `spec-guardian` |

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

## Appendix D — Orchestrator recipes (production flows)

Full definitions: `~/.cursor/ENGINEERING-RECIPES.md`

| Recipe | Use |
|--------|-----|
| `greenfield-feature` | New capability (default full pipeline) |
| `new-application` | Greenfield product + ARCH-000 |
| `bug-fix` | Defect — `.specs/maintenance/BUG-NNN.md` + parent REQ |
| `hotfix` | Urgent fix; backfill spec after merge |
| `maintenance` | Deps, refactor — ADR / ARCH delta |
| `infra-change` | Platform + SRE |
| `spec-only` | REQ/ARCH without code |
| `security-patch` | CVE / security findings |

Invoke: `/eng-orchestrator recipe: bug-fix — [description]` or skill `/spec-recipes`.

---

## Appendix C — Spec skills (installed)

| Skill | Path | Agent(s) |
|-------|------|----------|
| `spec-req-author` | `~/.cursor/skills/spec-req-author/` | requirements-analyst, qa-engineer |
| `spec-arch-author` | `~/.cursor/skills/spec-arch-author/` | architect, adr-recorder, data-engineer |
| `spec-challenger` | `~/.cursor/skills/spec-challenger/` | challenger |
| `spec-handoff` | `~/.cursor/skills/spec-handoff/` | all agents (end of phase) |
| `spec-verifier` | `~/.cursor/skills/spec-verifier/` | verifier, test-runner |
| `spec-guardian-drift` | `~/.cursor/skills/spec-guardian-drift/` | spec-guardian, code-reviewer |
| `spec-pipeline` | `~/.cursor/skills/spec-pipeline/` | eng-orchestrator (invoke `/spec-pipeline`) |
| `spec-recipes` | `~/.cursor/skills/spec-recipes/` | eng-orchestrator (invoke `/spec-recipes`) |
| `spec-agent-memory` | `~/.cursor/skills/spec-agent-memory/` | all agents (project `.cursor/agent-memory/`) |

---

## Appendix B — Quick reference: invoke the team

```
# Orchestrated feature (full pipeline)
/eng-orchestrator Add user profile API with React settings page

# Spec phase only
/requirements-analyst Define requirements for the notification system
/challenger Review .specs/requirements/REQ-001.md

# Implement against existing approved specs
/backend-engineer Implement REQ-001; read .specs/requirements/REQ-001.md and .specs/architecture/ARCH-001.md first
/frontend-engineer Build the settings UI per REQ-001 and ARCH-001

# Quality
/qa-engineer Write test plan for REQ-001
/test-runner Run tests and fix failures
/code-reviewer Review the auth module changes
/security-reviewer Review the payment module

# Verify
/verifier Confirm REQ-001 is fully implemented; read .specs/requirements/REQ-001.md

# Platform
/platform-engineer Add staging App Service Terraform module
/sre-devops Wire the new service into GitHub Actions deploy pipeline

# Consistency check
/spec-guardian Check .specs/ consistency against current repo
```

---

*This playbook is maintained by the agent team itself. Any change to agent behaviour, pipeline gates, or spec format must update this document first.*
