# Executive Summary: Spec-Driven AI Engineering with a Non-Conformist Agent Team

**Audience:** Engineering leadership, architecture, program management  
**Version:** 1.0 · May 2026  
**Companion docs:** `ENGINEERING-PLAYBOOK.md`, `~/.cursor/agents/`, `~/.cursor/skills/spec-*/`

---

## 1. What we are proposing

A **spec-driven engineering model** where durable requirements and architecture live in version-controlled `.specs/`, and a **specialized Cursor agent team** executes work against those specs—not against chat history or prior agent opinions.

A **non-conformist layer** prevents the usual AI failure mode: each agent validating the last agent’s story. Mandatory **challenger** reviews, a **verifier** that reads only the original requirement spec plus code, and **spec-guardian** drift checks keep the system honest over time.

**Code is an output of specs.** Specs are what future humans and agents maintain.

---

## 2. The four models compared

| Dimension | **Manual engineering team** | **AI-assisted development** | **Vibe-coded AI engineering** | **Spec-driven non-conformist AI team** (proposed) |
|-----------|----------------------------|----------------------------|------------------------------|---------------------------------------------------|
| **Source of truth** | Docs + tribal knowledge + code | Developer + IDE; AI as copilot | Chat session + generated code | `.specs/` (REQ, ARCH, ADR, contracts, test plans) |
| **Who decides “done”** | Reviewers, QA, PM sign-off | Developer judgment | “Looks good” in chat | REQ acceptance criteria + verifier + tests |
| **Speed to first demo** | Slower | Faster (completion assist) | Fastest | Slower upfront (spec + challenge gates) |
| **Speed at scale / maintenance** | Predictable if process disciplined | Variable | Often degrades (debt) | Improves if specs stay current |
| **Traceability** | Strong if process enforced | Weak unless disciplined | Very weak | Strong by design (REQ ↔ code ↔ tests) |
| **Risk of groupthink** | Human review bias | Low (human owns merge) | High (single agent narrative) | Reduced (challenger + isolated verifier) |
| **Cost model** | Headcount | Licenses + engineer time | Token spend + rework | Tokens × agents + lower rework if specs hold |
| **Best for** | Regulated, long-life systems | Day-to-day coding boost | Spikes, throwaways, prototypes | Products you will extend for years with agents |

### One-line definitions

- **Manual team:** Humans own requirements, design, implementation, and review; tools are secondary.
- **AI-assisted:** Human drives; AI suggests completions, refactors, tests—human remains accountable.
- **Vibe-coded:** Prompt → accept generated code with minimal spec/review discipline; optimizes for immediacy.
- **Spec-driven non-conformist agents:** Pipeline of roles (analyst → challenger → architect → implement → verify) bound to `.specs/` with adversarial gates.

---

## 3. How the proposed model works (condensed)

```
Intent → REQ (draft) → Challenger → REQ (APPROVED)
      → ARCH + ADRs + contracts (draft) → Challenger → ARCH (APPROVED)
      → Implement → Test plan → Test run → Review (parallel) 
      → Verifier (REQ + code only) → Spec guardian → DONE
```

**Non-conformist mechanisms**

| Mechanism | Problem it solves |
|-----------|-------------------|
| **Challenger (mandatory)** | Specs ship only after ≥2 substantive objections are addressed |
| **Verifier isolation** | Cannot “verify” from implementer summaries—only REQ + codebase + tests |
| **Spec-guardian** | Detects drift between specs and code after every change |
| **HANDOFF blocks** | Structured handoffs; paths to files, not prose chains |
| **Checkpoint + reset (Principle 8)** | Persist to disk at gates; fresh subagents; paths-only delegation |
| **Skills + agents** | Agents = roles; skills = templates/checklists (token-efficient) |

---

## 4. Expected benefits and costs

### Benefits

- **Maintainability:** New features and agents start from `.specs/`, not archaeology on old chats.
- **Auditability:** REQ acceptance criteria map to tests and verifier evidence—useful for compliance and incident review.
- **Parallel work:** Backend, frontend, QA plan can run in parallel once ARCH and contracts are approved.
- **Lower conformist risk** than single-agent or sequential “yes-machine” pipelines.

### Costs and trade-offs

- **Higher lead time before first line of code** (spec + two challenge cycles).
- **Higher token use** when running multiple subagents (mitigated by context-mode, spec files vs long handoffs).
- **Operational discipline:** Specs must be updated when behavior changes—spec-guardian enforces this.
- **Not a silver bullet:** Bad specs in → bad code out; quality of REQ/ARCH still depends on human intent and review.

---

## 5. Overkill risk and right-sizing

The full model is intentionally rigorous, but it is **not the default for every task or project**. If applied indiscriminately, it can recreate the coordination cost of a large human team: too many roles, too many handoffs, and too much document maintenance before the product has earned that overhead.

### Where the model can become overkill

| Overkill area | Failure mode | Right-sized alternative |
|---------------|--------------|-------------------------|
| **20 always-active agents** | Coordination overhead greater than the work | Start with 5 core roles; add specialists only on trigger |
| **Mandatory challenger on every small change** | Objections become compliance theater | Challenger required for APPROVED REQ/ARCH, optional for low-risk bugs |
| **Per-agent memory from day one** | Memory files rot or duplicate facts | One shared project memory until complexity grows |
| **Full contracts scaffold too early** | Empty OpenAPI/data/event files become ceremony | Create contracts when there is a real boundary or second consumer |
| **Spec-guardian on every tiny PR** | Slows hotfixes and low-risk maintenance | Run at release/sprint boundaries unless specs/contracts changed |
| **Formal HANDOFF on tiny tasks** | More process than value | Use a one-line handoff for tasks under one day |

### Complexity tiers

| Tier | Project / task profile | Agent footprint | Spec footprint | Gates |
|------|------------------------|-----------------|----------------|-------|
| **Tier 0 — Spike / throwaway** | Prototype, demo, disposable exploration | Main Agent only or `fullstack-engineer` | Notes only; no formal `.specs/` | Human judgment |
| **Tier 1 — Small app / solo builder** | MVP, low compliance, <5 core workflows | 5 roles: `eng-orchestrator`, `requirements-analyst`, one implementer, `test-runner`, `verifier` | REQ only; ARCH optional | Verifier before “done” |
| **Tier 2 — Productized app** | Maintained app with users, bugs, releases | 8–10 roles; add `architect`, `challenger`, reviewers, `spec-guardian` | REQ + ARCH + ADR for major choices | Challenger for REQ/ARCH, verifier, drift checks on releases |
| **Tier 3 — Enterprise / regulated** | Security, PII, infra, multi-team ownership | Full 20-agent team | Full `.specs/` tree: contracts, test plans, ADRs, memory | Full gates on feature work; recipe-specific gates for ops |

### Recommended default

Start at **Tier 1** for a new application unless there is already regulatory, security, multi-team, or infrastructure complexity. Promote to Tier 2 only when one of these triggers appears:

- More than one long-lived feature area
- More than one deployable service or external API consumer
- Security-sensitive data, payments, auth, or PII
- Repeated bugs caused by missing requirements or unclear architecture
- A second agent or human needs to resume work from specs without re-asking context

Promote to Tier 3 only when the cost of drift or defects is higher than the cost of ceremony.

### Minimum viable spec-driven team

For most small projects, use this **5-role minimum**:

```
eng-orchestrator
requirements-analyst → REQ
fullstack-engineer (or backend/frontend)
test-runner
verifier
```

Use `challenger` manually before important approvals, not on every small patch. Add `architect` when the implementation crosses a durable boundary: database model, public API, auth, deployment topology, or major framework choice.

---

## 6. Is there data on spec-driven AI engineering teams?

### Short answer

**There is growing industry and academic work on spec-driven development (SDD) with AI agents, but almost no published benchmarks for multi-agent, adversarial (“non-conformist”) pipelines like ours.** Treat productivity claims as directional until you measure on your own codebase.

### What exists today (May 2026)

| Topic | What data / sources say | Relevance to our model |
|-------|-------------------------|------------------------|
| **Spec-driven development (general)** | Thoughtworks, GitHub Spec Kit, and practitioner guides describe SDD as a 2025–2026 practice: specs as living artifacts; Specify → Plan → Tasks → Implement ([Thoughtworks](https://www.thoughtworks.com/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices), [GitHub Blog](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)). | Aligns with REQ/ARCH/contracts in `.specs/`. We add **challenger + verifier isolation**, which most toolkits do not formalize. |
| **Context-grounded specs (research)** | arXiv work on “Spec Kit Agents” discusses grounding spec stages in repo evidence and validating intermediate artifacts to reduce incompatible specs ([arXiv:2604.05278](https://arxiv.org/abs/2604.05278)). | Similar intent to **spec-guardian** and contract files. |
| **AI-assisted development (RCTs / enterprise)** | Google RCT (~96 engineers): ~**21%** faster task completion with AI tools ([arXiv:2410.12944](https://arxiv.org/abs/2410.12944)). Microsoft-led field experiments (~4,867 devs): ~**26%** more completed tasks ([Microsoft Research](https://www.microsoft.com/en-us/research/publication/the-effects-of-generative-ai-on-high-skilled-work-evidence-from-three-field-experiments-with-software-developers/)). Enterprise platform study (~300 engineers): ~**32%** PR review cycle reduction ([arXiv:2509.19708](https://arxiv.org/abs/2509.19708)). | Applies to **copilot-style assist**, not full spec-gated multi-agent teams. Useful baseline for “AI helps” vs “AI owns pipeline.” |
| **Mixed / null activity metrics** | Longitudinal study (703 repos): no significant change in commit-based activity after Copilot adoption despite positive developer perception ([arXiv:2509.20353](https://arxiv.org/abs/2509.20353)). | Warns: **velocity metrics ≠ quality or maintainability.** Our model should measure REQ coverage and drift, not just commits. |
| **Vibe coding / AI-generated code quality** | Large study of AI-authored commits: hundreds of thousands of issues; **~24%** persist as long-term debt ([arXiv:2603.28592](https://arxiv.org/abs/2603.28592)). Industry surveys: AI PRs ~**1.7×** more issues; scan reports ~**1%** “production-ready” without hardening ([examples](https://tech-stack.com/blog/state-of-ai-report-2026/), [Astro vibe report](https://useastro.com/vibe-code-report/)). | Supports **why** spec + verify + challenger beats prompt-only generation. |
| **Multi-agent non-conformist teams** | **No standard benchmark** found for “challenger-gated REQ/ARCH + verifier reads only REQ.” Cursor documents subagents and orchestration; this is **organizational pattern + your playbook**, not a vendor metric. | **You should run internal pilots** (see §8). |

### What is *not* proven publicly

- That a 15–20 agent Cursor team outperforms a senior manual team on **time-to-production** for greenfield apps.
- That mandatory challenger gates always net-positive ROI on small features.
- That spec-driven agents reduce incidents without investment in spec quality and CI.

---

## 7. Positioning vs alternatives (executive view)

### vs manual engineering team

| | Manual | Spec-driven agents |
|---|--------|-------------------|
| **Wins** | Judgment, context, accountability, proven hiring model | Speed of execution once specs exist, 24/7 pipeline, consistent checklists |
| **Loses** | Cost, bus factor, slow doc updates | Upfront spec cost; needs human product intent |
| **Hybrid** | Humans own product judgment and APPROVED specs; agents execute and verify |

**Recommendation:** Keep humans on **intent, approval, and exception handling**. Agents on **drafting specs, implementation, test execution, drift detection**.

### vs AI-assisted development (Copilot / inline Agent)

| | AI-assisted | Spec-driven agents |
|---|-------------|-------------------|
| **Wins** | Lowest friction, developer stays in flow | End-to-end feature traceability, adversarial review |
| **Loses** | Easy to skip specs and tests | More process, more tokens |
| **Hybrid** | Use assist inside implementer agents; keep gates |

**Recommendation:** AI-assisted is the **default daily mode**; spec-driven pipeline is the **mode for features, releases, and refactors** that must live longer than a sprint.

### vs vibe-coded AI engineering

| | Vibe-coded | Spec-driven agents |
|---|------------|-------------------|
| **Wins** | Fastest prototype | Sustainable codebase, agent-maintainable |
| **Loses** | Debt, security gaps, no audit trail | Slower start |
| **Evidence** | Industry data shows higher defect rates and persistent debt in unreviewed AI code | Designed explicitly to counter that |

**Recommendation:** Allow vibe coding only for **throwaway spikes**; promote spike learnings into REQ/ARCH before production merge.

---

## 8. How to measure success (recommended KPIs)

Because public benchmarks for our exact model are scarce, define **internal** metrics:

| KPI | What it tells you |
|-----|-------------------|
| **REQ criterion coverage** | % acceptance criteria with passing test + verifier sign-off |
| **Spec drift rate** | spec-guardian findings per release |
| **Rework after “done”** | Defects traced to missing/wrong spec vs code bug |
| **Time in gates** | Hours in DRAFT vs APPROVED (tune challenger strictness) |
| **Token cost per shipped REQ** | Cost vs vibe-coded baseline on similar scope |
| **Lead time** | Intent → APPROVED ARCH → production (compare to manual baseline) |

Run an **A/B pilot** on two similar features: vibe-coded vs spec-driven pipeline on the same repo.

---

## 9. Recommendation

| Organization goal | Recommended approach |
|-------------------|---------------------|
| Prototype / demo in days | Vibe-coded or AI-assisted |
| Incremental productivity on existing team | AI-assisted + light REQ for large changes |
| **Product you will maintain with AI agents for years** | **Spec-driven non-conformist agent team** |
| Regulated / high-trust domain | Spec-driven + manual approval on APPROVED specs |

**Investment order:** (1) start with Tier 1 footprint, (2) add `.specs/` and core agents, (3) pilot one feature end-to-end, (4) measure KPIs in §8, (5) promote to Tier 2/3 only when complexity triggers justify it.

---

## 10. References (external)

- Thoughtworks — [Spec-driven development (2025 practices)](https://www.thoughtworks.com/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices)
- GitHub — [Spec-driven development toolkit](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
- Google — AI impact RCT ([arXiv:2410.12944](https://arxiv.org/abs/2410.12944))
- Microsoft Research — Field experiments on developer productivity ([publication](https://www.microsoft.com/en-us/research/publication/the-effects-of-generative-ai-on-high-skilled-work-evidence-from-three-field-experiments-with-software-developers/))
- AI-generated code debt study ([arXiv:2603.28592](https://arxiv.org/abs/2603.28592))
- Cursor — [Subagents](https://cursor.com/docs/agent/subagents) · [Agent Skills](https://cursor.com/docs/skills)

---

## 11. Production workflow recipes

After go-live, the orchestrator selects a **recipe** (not always the full feature pipeline):

| Recipe | Typical use |
|--------|-------------|
| `greenfield-feature` | New capabilities |
| `bug-fix` | Defects (BUG doc + parent REQ) |
| `hotfix` | Urgent production fixes |
| `maintenance` | Upgrades, refactors |
| `infra-change` | IaC, CI/CD |

Details: `~/.cursor/ENGINEERING-RECIPES.md` · invoke `/spec-recipes`

---

## 12. Internal assets (this installation)

| Asset | Location |
|-------|----------|
| Playbook | `~/.cursor/ENGINEERING-PLAYBOOK.md` |
| Agents (20) | `~/.cursor/agents/` |
| Spec skills (7) | `~/.cursor/skills/spec-*/` |
| App template | `~/.cursor/templates/spec-driven-app/` |
| Invoke cheat sheet | `/spec-pipeline` |

---

*This document is strategic guidance, not a performance guarantee. Validate on your codebase with the pilot metrics in Section 8.*
