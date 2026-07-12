# SpecForge Engineering Team

**SpecForge** is an installable spec-driven engineering team for **Cursor**, **Claude Code**, **Codex CLI**, and **OpenCode**: 20 agents, 19 skills, 5 checkpoint hooks (Cursor), **token discipline**, **release benchmarking**, project memory, and a bootstrap template.

> Specs are source of truth. Chat is ephemeral. Memory learns on disk. Tokens are measured, not guessed.

## Install

### Option A — All platforms (recommended)

```bash
git clone https://github.com/sushilti80/specforge-engineering-team.git
cd specforge-engineering-team
bash scripts/install-all.sh
```

`install-all.sh` syncs **Ponytail** skills from upstream, then installs Cursor, Claude, Codex, and OpenCode.

### Option B — Cursor only

```bash
bash scripts/sync-ponytail.sh   # optional if skills/ already committed
bash scripts/install.sh
```

Restart Cursor → **Settings → Plugins** → enable **specforge-engineering-team**.

### Option C — Claude Code only

```bash
bash scripts/install-claude.sh
```

### Option D — Codex CLI

```bash
bash scripts/install-codex.sh
```

Skills install to `~/.agents/skills/`; docs to `~/.codex/specforge/`.

### Option E — OpenCode

```bash
bash scripts/install-opencode.sh
```

Agents, skills, and commands install to `~/.config/opencode/`.

See [`docs/MULTI-TOOL.md`](docs/MULTI-TOOL.md) for parity details and per-tool quickstarts.

## After install — verify and run

`install-all.sh` does **not** put agents inside a random project folder. It **symlinks** this repo into each tool’s user directory. Agents still live in this repo’s `agents/` folder.

### Where things landed (macOS/Linux)

| Tool | Agents / plugin path |
|------|----------------------|
| **Cursor** | `~/.cursor/plugins/local/specforge-engineering-team` → this repo (agents at `.../agents/`) |
| **Claude Code** | `~/.claude/agents/*.md` (symlinks) |
| **OpenCode** | `~/.config/opencode/agents/*.md` (symlinks) |
| **Codex CLI** | No agent files — skills in `~/.agents/skills/`, instructions in `~/.codex/AGENTS.md` |

Quick check:

```bash
ls -la ~/.cursor/plugins/local/specforge-engineering-team
ls ~/.cursor/plugins/local/specforge-engineering-team/agents | head
ls -la ~/.claude/agents | head
```

You should see arrows (`->`) pointing back into this repo.

### Cursor — enable and smoke-test

1. **Restart Cursor** after install.
2. **Settings → Plugins** (or Customize) → enable **specforge-engineering-team**.
3. Open **Agent** chat (not only inline Tab).
4. Type `/` — you will see **many** names. That is expected:
   - **Commands** (start here): `/spec-pipeline`, `/eng-orchestrator`, `/bootstrap-spec-project`
   - **Agents** (roles the orchestrator uses): `/backend-engineer`, `/challenger`, `/verifier`, …
5. **Do not** run every agent yourself. Start with the orchestrator or pipeline command.

**Minimal smoke test (no app yet):**

```
/eng-orchestrator

Need: advisory — what does SpecForge do and which recipe for a new small app?
Tier: 0
Suggested recipe: advisory-only
```

You should get a short advisory answer (readonly). If the agent runs, install + plugin enable worked.

### Bootstrap a real project (recommended)

Agents are most useful **inside an app repo** with `.specs/` and memory:

```bash
bash scripts/bootstrap-project.sh /path/to/your-app
cd /path/to/your-app
```

Commit `.specs/`, `.agents/memory/`, and `AGENTS.md`. Open **that folder** as the Cursor workspace, then run the first prompt below.

### First prompt (after bootstrap)

**Cursor / OpenCode** — type `/` and pick **`/spec-pipeline`** or **`/eng-orchestrator`**, then paste:

```
Tier: 1
Recipe: new-application

Build a [your app — 2–5 sentences].
```

The orchestrator picks the next agents (requirements-analyst → challenger → …). You only need to approve gates and answer questions.

| You type | What happens |
|----------|----------------|
| `/eng-orchestrator` or `/spec-pipeline` | **Normal entry** — full pipeline |
| `/requirements-analyst` | Only write/update a REQ (advanced) |
| `/backend-engineer` | Only implement (needs APPROVED REQ+ARCH) |
| `/verifier` | Only verify vs REQ |

**Codex / Claude:** same tier/recipe block in chat; act as eng-orchestrator (see project `AGENTS.md`). Claude: agents appear by name under `~/.claude/agents/`.

### If `/` shows agents but nothing useful happens

| Symptom | Fix |
|---------|-----|
| Plugin missing in Settings | Re-run `bash scripts/install.sh`, restart Cursor |
| Agents listed but ignore `.specs/` | Open a **bootstrapped** project folder as the workspace |
| Wrong project | `cd` to your app, not only the harness `cursorteam` repo |
| Want install paths only | `ls -la ~/.cursor/plugins/local/specforge-engineering-team` |

## What's included

| Component | Count | Purpose |
|-----------|-------|---------|
| **Agents** | 20 | Orchestrator, analysts, implementers, QA, reviewers, verifier, challenger |
| **Spec skills** | 13 | Pipeline, recipes, handoffs, memory, metrics, advisory, token budget, vendor sync |
| **Ponytail skills** | 6 | Minimal code ladder, diff/repo bloat review, debt ledger ([upstream](https://github.com/DietrichGebert/ponytail)) |
| **Rules** | 4 | Spec gates, agent memory, ponytail, token discipline (Cursor) |
| **Commands** | 3 | `/spec-pipeline`, `/eng-orchestrator`, `/bootstrap-spec-project` |
| **Hooks** | 5 | sessionStart, beforeSubmitPrompt, subagentStop, afterFileEdit, stop |
| **Docs** | 7 | Playbook, recipes, bootstrap, executive summary, multi-tool, roadmap, **metrics** |

## Token discipline

Stop **review chats from turning into implement sessions** and cap **output bloat** without cutting spec quality. Token efficiency is a first-class harness feature — not an afterthought.

### What it does

| Mechanism | What happens |
|-----------|----------------|
| **`rules/token-discipline.mdc`** | Always-on: verdict-first replies, advisory = readonly, paths over chat replay |
| **`beforeSubmitPrompt` hook** (Cursor) | Detects review / docs / vendor-sync prompts → injects budget + mode |
| **`spec-advisory`** | Readonly reviews — no file edits unless you say *implement* |
| **`spec-token-budget`** | Output caps by profile (advisory ≤800w, handoff ≤500w, docs-touch, release) |
| **Meta recipes** | Split sessions like Principle 8 — advisory ≠ build |

### Meta recipes (save parent context)

| Recipe | Use when | Edits? |
|--------|----------|--------|
| `advisory-only` | "Should we…", compare, feasibility, critical review | Readonly |
| `vendor-sync` | `sync-ponytail.sh`, pull upstream skills | Harness only |
| `docs-touch` | README, ROADMAP, acknowledgments | Docs only |

**Pattern:** decide in one chat → **new chat** to implement with paths only.

```
/eng-orchestrator recipe: advisory-only — should we add GitHub Copilot next?
```

After the verdict, start fresh:

```
Recipe: greenfield-feature | Tier: 1
Read: .specs/decisions/DEC-001.md
Do not use prior chat summaries.
```

### Hooks & hygiene (Cursor)

| Hook | Token role |
|------|------------|
| `beforeSubmitPrompt` | Route advisory / docs / vendor intent |
| `subagentStop` | Checkpoint + compress HANDOFF + `session.jsonl` metrics |
| `sessionStart` | Principle 8 + journal tail (≤8 lines) |
| `stop` | Nudge `distill-learning-journal.sh` |

**Weekly:** `bash scripts/distill-learning-journal.sh` — shrinks sessionStart input over time.

**Complement:** [context-mode](https://github.com/mksglu/context-mode) for sandboxing large tool output (playbook §7). Separate install; recommended for long pipelines.

Skills: `spec-advisory`, `spec-token-budget`, `spec-vendor-sync` · playbook §7

## Release benchmarking

Measure **tokens per REQ**, **subagent activity**, and **quality KPIs** at release — without pretending hooks expose exact billing APIs.

### Three measurement tiers

| Tier | Source | Use for |
|------|--------|---------|
| **A — Billing** | Cursor/Codex usage export | Ground truth $ and total tokens |
| **B — Proxies** | `session.jsonl` + gate files + `ctx stats` | Per-release trends |
| **C — Heuristics** | `estimate-pipeline-tokens.sh` | Planning, recipe compare (±30–50%) |

### Commands

```bash
# Heuristic: e.g. greenfield-feature Tier 1 ≈ 188K tokens total
bash scripts/estimate-pipeline-tokens.sh greenfield-feature --tier 1

# Proxies: subagent counts, git diff, gate checkpoints since last tag
bash scripts/collect-release-metrics.sh --since v1.2.0

# Scorecard → .specs/metrics/releases/REL-YYYY-MM-DD.yaml (skill spec-release-metrics)
```

### What gets tracked

| Metric | Why it matters |
|--------|----------------|
| **Est. input / output tokens** | Cost per release and per recipe |
| **Tokens per shipped REQ** | Compare vibe-coded vs spec-driven |
| **Subagent runs by role** | `subagentStop` → `metrics/session.jsonl` |
| **Gate checkpoints** | Principle 8 compliance |
| **context-mode savings ratio** | Effective input reduction |
| **Verifier gaps + spec drift** | Never optimize tokens without quality |

Tier 2+ ceremony: spec-guardian → collect metrics → write `REL-*.yaml`.

Full framework: [`docs/ENGINEERING-METRICS.md`](docs/ENGINEERING-METRICS.md) · skill **`spec-release-metrics`**

## Ponytail (minimal code)

[Ponytail](https://github.com/DietrichGebert/ponytail) stops AI over-engineering: reuse → stdlib → native → minimum code, without cutting validation or security.

| Skill | When |
|-------|------|
| `ponytail` | Implementers — always-on minimalism ladder |
| `ponytail-review` | Gate 3 — parallel with code/security review |
| `ponytail-audit` | Maintenance — whole-repo bloat scan |
| `ponytail-debt` | List deferred `ponytail:` shortcuts |

Refresh from upstream: `bash scripts/sync-ponytail.sh`

## Tiers (right-sizing)

| Tier | Use |
|------|-----|
| 0 | Spike — no formal specs |
| 1 | MVP / small app (default) |
| 2 | Product with releases |
| 3 | Enterprise / regulated — full pipeline |

## Recipes

**Production:** `new-application` · `greenfield-feature` · `bug-fix` · `hotfix` · `maintenance` · `infra-change` · `spec-only` · `security-patch`

**Meta (token discipline):** `advisory-only` · `vendor-sync` · `docs-touch`

See `docs/ENGINEERING-RECIPES.md`.

## Persistent agent memory (self-improvement)

Agents learn across conversations via **project-scoped** memory (commit to git):

| Path | Purpose |
|------|---------|
| `.agents/memory/_project/MEMORY.md` | Shared stack, conventions (≤200 lines) |
| `.agents/memory/_project/specs-index.md` | REQ / ARCH / BUG status |
| `.agents/memory/<agent>/MEMORY.md` | Per-role lessons (all 20 agents) |
| `.agents/memory/<agent>/<topic>.md` | Deep notes; link from MEMORY.md |

**Flow:** read memory at start → work against `.specs/` → update lessons at end (skill `spec-agent-memory`). Cursor `sessionStart` injects a short `_project/MEMORY.md` summary (≤30 useful lines) so agents see prior learnings without a full file read.

Bootstrap creates stubs: `bash scripts/bootstrap-agent-memory.sh` (also run by `bootstrap-project.sh`).

## Self-learning (Cursor hooks)

When the Cursor plugin is enabled on a bootstrapped project:

1. **`sessionStart`** → Principle 8 + token discipline + **project memory summary** + recent journal
2. **`beforeSubmitPrompt`** → advisory / docs / vendor intent routing
3. **`subagentStop`** → gate checkpoint + HANDOFF compression + `session.jsonl` metrics
4. **`afterFileEdit`** → logs `.specs/` and memory edits to `learning-journal.md`
5. **`stop`** → nudges journal distillation + fresh chat for next gate

Other tools: follow the manual checkpoint checklist in `docs/MULTI-TOOL.md`; use skills `spec-advisory` and `spec-token-budget` explicitly.

## Roadmap & community

**Supported today:** Cursor, Claude Code, Codex CLI, OpenCode.

**Next up:** **GitHub Copilot** (Phase 2 — `install-copilot.sh`, `.github/agents/`, `.github/skills/`).

**Help wanted (after Copilot):** ForgeCode, Aider, Windsurf, Cline, Kiro, and others. See [`docs/ROADMAP.md`](docs/ROADMAP.md) for contribution guidelines.

If you maintain or use another open-source coding agent, PRs for `scripts/install-<tool>.sh` are welcome.

## Repository layout

```
specforge-engineering-team/
├── .cursor-plugin/plugin.json
├── agents/
├── skills/
│   ├── spec-*              # 13 spec-driven skills (incl. metrics, advisory, token budget)
│   └── ponytail*           # 6 ponytail skills (synced from upstream)
├── rules/                  # spec-driven, agent-memory, ponytail, token-discipline
├── commands/
├── hooks/                  # 5 events (incl. beforeSubmitPrompt)
├── docs/
│   ├── ENGINEERING-METRICS.md   # release benchmarking framework
│   └── ROADMAP.md
├── vendor/ponytail/
├── templates/
└── scripts/
    ├── install*.sh
    ├── sync-ponytail.sh
    ├── estimate-pipeline-tokens.sh    # Tier C heuristics
    ├── collect-release-metrics.sh     # Tier B proxies
    ├── distill-learning-journal.sh    # shrink sessionStart input
    └── bootstrap-project.sh
```

## Acknowledgments

SpecForge builds on ideas and tooling the open-source community shared first. We are grateful to the projects and people below.

### Dietrich Gebert — [Ponytail](https://github.com/DietrichGebert/ponytail)

Thank you, **Dietrich**, for open-sourcing Ponytail and for the “lazy senior dev” framing that changed how we think about AI-generated code. Your YAGNI → reuse → stdlib → native → minimum ladder gave SpecForge a missing piece: **minimal implementation** without dropping validation, security, or accessibility.

We vendored six Ponytail skills under MIT (`vendor/ponytail/`, synced via `bash scripts/sync-ponytail.sh`) and wired them into Gate 3 review and our implementer agents. The always-on Cursor rule in bootstrapped projects is yours — we are users and integrators, not authors of that concept.

If Ponytail helps your team ship smaller diffs, **[star the repo](https://github.com/DietrichGebert/ponytail)** and say thanks upstream.

### [context-mode](https://github.com/mksglu/context-mode)

Thank you to the **context-mode** maintainers for the sandboxed execution model that keeps verbose tool output out of the agent context window. SpecForge’s playbook (§7 Token Efficiency) assumes complementary tooling like `ctx_execute`, `ctx_execute_file`, and BM25 search — the same “minimal context, maximum signal” principle we apply to specs and handoffs.

context-mode is a **separate install** (Cursor marketplace or MCP plugin), not bundled in this repo. We recommend it alongside SpecForge when agents run long pipelines, large test suites, or multi-file reviews. See the [context-mode README](https://github.com/mksglu/context-mode) for setup.

### Other open source we build on

| Project | Contribution |
|---------|----------------|
| [**AGENTS.md**](https://agents.md/) | Cross-tool project instructions — entry point for Cursor, Codex, Claude, and OpenCode |
| **Agent skills & plugins ecosystem** | Cursor, Claude Code, OpenCode, and Codex CLI — the harness model we install into |

If we missed a project your work drew from, open an issue or PR — we are happy to credit it here.

## License

MIT — see [LICENSE](LICENSE). Ponytail skills are MIT — see [vendor/ponytail/LICENSE](vendor/ponytail/LICENSE).
