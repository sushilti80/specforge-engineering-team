# SpecForge multi-tool guide

SpecForge ships one harness (agents, skills, docs) and installs it into each AI tool's native discovery paths.

## Install

| Platform | Command | What gets linked |
|----------|---------|------------------|
| **All** | `bash scripts/install-all.sh` | Cursor + Claude + Codex + Copilot + OpenCode |
| **Cursor** | `bash scripts/install.sh` | Plugin + docs in `~/.cursor/` |
| **Claude Code** | `bash scripts/install-claude.sh` | `~/.claude/agents/`, `~/.claude/skills/`, docs |
| **Codex CLI** | `bash scripts/install-codex.sh` | `~/.agents/skills/`, `~/.codex/specforge/`, global `~/.codex/AGENTS.md` |
| **Copilot CLI** | `bash scripts/install-copilot.sh` | `~/.copilot/agents/*.agent.md`, `~/.agents/skills/`, `~/.copilot/specforge/`, `~/.copilot/hooks/specforge.json` |
| **Copilot Cloud** | `bash scripts/bootstrap-project.sh --platform copilot` | `.github/agents/`, `.github/skills/`, `.github/hooks/`, `scripts/specforge-hooks/` (vendored, repo-local) |
| **ForgeCode** | `bash scripts/install-forge.sh` | `~/.forge/agents/*.md`, `~/.agents/skills/`, `~/.forge/specforge/`, global `~/.forge/AGENTS.md` |
| **OpenCode** | `bash scripts/install-opencode.sh` | `~/.config/opencode/{agents,skills,commands,specforge}/` |

Bootstrap a project:

```bash
bash scripts/bootstrap-project.sh /path/to/your-app
# Or platform-specific overlay only:
bash scripts/bootstrap-project.sh --platform opencode /path/to/your-app
```

## SPECFORGE_HOME

Agents and skills reference **`SPECFORGE_HOME`** for playbook and recipes. Resolve from the first path that exists:

| Platform | SPECFORGE_HOME |
|----------|----------------|
| Cursor | `~/.cursor/` |
| Codex | `~/.codex/specforge/` |
| OpenCode | `~/.config/opencode/specforge/` |
| Claude Code | `~/.claude/docs/specforge/` |
| Copilot | `~/.copilot/specforge/` (CLI) or `.github/` (Cloud Agent) |
| ForgeCode | `~/.forge/specforge/` (CLI) or `.forge/` (project-local) |

## Parity matrix

| Capability | Cursor | Claude | OpenCode | Codex | Copilot | ForgeCode |
|------------|--------|--------|----------|-------|---------|-----------|
| 20 agents | plugin | symlink | symlink | via AGENTS.md + skills | `.github/agents` (cloud) / `~/.copilot/agents` (CLI) | `~/forge/agents` (symlink, `id:`+`name:`) |
| 15 skills (9 spec + 6 ponytail) | plugin | symlink | symlink | `~/.agents/skills` | `.github/skills` (cloud) / `~/.agents/skills` (CLI) | `~/.agents/skills` (load on demand) |
| Ponytail minimal-code rule | `rules/ponytail.mdc` | skill only | skill only | skill only | skill only | skill only |
| Slash / entry | `/eng-orchestrator` (pref); `/spec-pipeline` cheat sheet | prompt in AGENTS.md | `@eng-orchestrator` (pref); `/spec-pipeline` cheat sheet | need/tier prompt in AGENTS.md | `@eng-orchestrator` with need/tier | `:agent eng-orchestrator` with need/tier |
| Hooks / automation | 5 (plugin) | 5 (global settings) | plugins TBD | 5 (`~/.codex/hooks.json`) | 5 (`~/.copilot/hooks/specforge.json` CLI; `.github/hooks/specforge.json` cloud) | none (PR #2757 closed; manual checklist) |
| Project memory | `.agents/memory/` | same | same | same | same | same |
| Spec gates | rules + AGENTS.md | AGENTS.md | AGENTS.md | AGENTS.md | AGENTS.md + `.github/copilot-instructions.md` | AGENTS.md (manual checklist) |
| Project entry | AGENTS.md | AGENTS.md | AGENTS.md | AGENTS.md | AGENTS.md | AGENTS.md (auto-loaded, walks git root→CWD) |

## Ponytail (all supported platforms)

Six skills from [ponytail](https://github.com/DietrichGebert/ponytail) (MIT), synced via `bash scripts/sync-ponytail.sh`:

| Skill | Role |
|-------|------|
| `ponytail` | Implementers — YAGNI → reuse → stdlib → native → minimum |
| `ponytail-review` | Gate 3 — diff audit for over-engineering |
| `ponytail-audit` | Maintenance — repo-wide bloat |
| `ponytail-debt` | Track deferred `ponytail:` shortcuts |

Cursor also loads **`rules/ponytail.mdc`** (always-on). Bootstrapped projects copy it to `.cursor/rules/`.

## Start work by tool

### Cursor

```
/eng-orchestrator

Tier: 1

Build a [your app — 2–5 sentences].

Run need checklist; smallest recipe × tier; minimal agents_planned;
stop for user APPROVED on REQ before implement.
```

`/spec-pipeline` is an entry cheat sheet only — it defers to `ENGINEERING-RECIPES.md` §0.

### OpenCode

Prefer `@eng-orchestrator` with need + tier (same block as Cursor). `/spec-pipeline` only as a cheat sheet that defers to recipes §0.

### Codex CLI

Use the prompt template from project `AGENTS.md` or global `~/.codex/AGENTS.md`:

```
Need: [capability | bug | hotfix | greenfield product …]
Tier: 1
Suggested recipe: [or let orchestrator pick from ENGINEERING-RECIPES §0]

[2–5 sentences]. Stop at READY_FOR_APPROVAL — I own Status: APPROVED.
```

Act as **eng-orchestrator** — need checklist → matrix → HANDOFF with agents_planned.

### Claude Code

Invoke agents by name (e.g. `eng-orchestrator`) or paste the same tier/recipe template. Skills load from `~/.claude/skills/`.

### Copilot

Two install modes:

- **Copilot CLI** — `bash scripts/install-copilot.sh` links agents (`~/.copilot/agents/*.agent.md`), skills, docs, and registers 5 hooks in `~/.copilot/hooks/specforge.json`. Invoke `@eng-orchestrator` with the need/tier block.
- **Copilot Cloud Agent** — `bash scripts/bootstrap-project.sh --platform copilot /path/to/project` vendors everything into `.github/` (agents, skills, hooks) and `scripts/specforge-hooks/` (bridge + core scripts) with **relative paths**. Commit these so the cloud runner can execute hooks without `$HOME` access.

### ForgeCode

`bash scripts/install-forge.sh` symlinks agents into `~/.forge/agents/*.md` (SpecForge agents carry both `name:` for Cursor/Claude and `id:` for ForgeCode — ForgeCode requires `id` and does not fall back to `name`). Skills live in the cross-tool `~/.agents/skills/` (ForgeCode has no native skills path; load on demand via AGENTS.md). ForgeCode auto-loads `~/.forge/AGENTS.md` at every conversation start.

Switch agents with `:agent eng-orchestrator` (or `:agent` picker), then paste the need/tier block. **No hooks** — ForgeCode's user-configurable hooks PR (#2757) was closed without merging, so gate checkpoints are a manual checklist (same parity tier as OpenCode).

## Project layout (all tools)

```
your-app/
├── AGENTS.md              ← always-on project instructions
├── .specs/                ← source of truth (REQ, ARCH, ADR, contracts)
├── .agents/
│   ├── memory/            ← durable agent memory (canonical)
│   └── skills/            ← optional project skill symlinks
├── .cursor/
│   ├── rules/             ← Cursor-only rules
│   └── agent-memory → ../.agents/memory
└── .opencode/             ← optional project agent/command symlinks
    ├── agents/
    └── commands/
```

## Gate checkpoint (Claude / Codex / Copilot / ForgeCode / OpenCode)

**Claude, Codex, and Copilot:** SpecForge install registers the same 5 checkpoint hooks via `hooks/adapters/bridge.py`. Codex requires a one-time `/hooks` trust after install. Copilot CLI writes `~/.copilot/hooks/specforge.json`; Copilot Cloud uses repo-local `.github/hooks/specforge.json` with vendored `scripts/specforge-hooks/`.

**ForgeCode and OpenCode (no user-configurable hooks):** follow this checklist manually at each gate:

1. Update `.specs/` files if changed
2. Update `.agents/memory/_project/specs-index.md`
3. Update `.agents/memory/<agent>/MEMORY.md`
4. Optionally write `.specs/handoffs/GATE-*.md`
5. Delegate to next agent with **paths only** (≤500 words) — fresh session per gate

## Migrating existing projects

If your project has `.cursor/agent-memory/` as a real directory (not a symlink):

```bash
mv .cursor/agent-memory .agents/memory
ln -sfn ../.agents/memory .cursor/agent-memory
```

Commit `.agents/memory/` and `AGENTS.md`.

## Next up — OpenCode hooks + ForgeCode hooks

Copilot (CLI + Cloud) and ForgeCode (agents) are now shipped. The next adapter work:

- **OpenCode hooks** — evaluate plugin lifecycle API for the same 5 checkpoint events.
- **ForgeCode hooks** — revisit when ForgeCode merges a user-configurable hook system upstream (PR #2757 was closed 2026-04-28; the contract mirrors Claude Code, so a `bridge.py --platform forge` alias will be straightforward once it lands).
- **More platforms** — Aider, Windsurf, Cline, Kiro (see [`ROADMAP.md`](ROADMAP.md)).

Community: PRs and issue `[platform] <tool> install adapter` welcome.

## Hook parity

| Platform | Status |
|----------|--------|
| **Cursor** | 5 hooks via plugin `hooks/hooks.json` |
| **Claude Code** | 5 hooks via `install-claude.sh` → `~/.claude/settings.json` + `hooks/adapters/bridge.py` |
| **Codex CLI** | 5 hooks via `install-codex.sh` → `~/.codex/hooks.json` + bridge (trust with `/hooks`) |
| **Copilot CLI** | 5 hooks via `install-copilot.sh` → `~/.copilot/hooks/specforge.json` + bridge (`--platform copilot`) |
| **Copilot Cloud** | 5 hooks via `bootstrap-project.sh --platform copilot` → `.github/hooks/specforge.json` (vendored `scripts/specforge-hooks/`) |
| **ForgeCode** | none — user-configurable hooks PR #2757 closed without merging; manual gate checklist (revisit when upstream ships hooks) |
| **OpenCode** | evaluate plugin lifecycle API — manual checklist until then |

Same core scripts: [`hooks/scripts/`](../hooks/scripts/).
