# SpecForge multi-tool guide

SpecForge ships one harness (agents, skills, docs) and installs it into each AI tool's native discovery paths.

## Install

| Platform | Command | What gets linked |
|----------|---------|------------------|
| **All** | `bash scripts/install-all.sh` | Cursor + Claude + Codex + OpenCode |
| **Cursor** | `bash scripts/install.sh` | Plugin + docs in `~/.cursor/` |
| **Claude Code** | `bash scripts/install-claude.sh` | `~/.claude/agents/`, `~/.claude/skills/`, docs |
| **Codex CLI** | `bash scripts/install-codex.sh` | `~/.agents/skills/`, `~/.codex/specforge/`, global `~/.codex/AGENTS.md` |
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

## Parity matrix

| Capability | Cursor | Claude | OpenCode | Codex | Copilot (**next**) |
|------------|--------|--------|----------|-------|-------------------|
| 20 agents | plugin | symlink | symlink | via AGENTS.md + skills | `.github/agents` |
| 15 skills (9 spec + 6 ponytail) | plugin | symlink | symlink | `~/.agents/skills` | `.github/skills` |
| Ponytail minimal-code rule | `rules/ponytail.mdc` | skill only | skill only | skill only | TBD |
| Slash commands | `/spec-pipeline` | manual | `/spec-pipeline` | prompt in AGENTS.md | custom agents |
| Hooks / automation | 4 hooks | none | plugins TBD | `.codex` hooks TBD | none |
| Project memory | `.agents/memory/` | same | same | same | same |
| Spec gates | rules + AGENTS.md | AGENTS.md | AGENTS.md | AGENTS.md | AGENTS.md |
| Project entry | AGENTS.md | AGENTS.md | AGENTS.md | AGENTS.md | AGENTS.md |

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
/spec-pipeline

Tier: 1
Recipe: new-application

Build a [your app — 2–5 sentences].
```

### OpenCode

```
/spec-pipeline
```

Or invoke `@eng-orchestrator` with tier and recipe in the prompt.

### Codex CLI

Use the prompt template from project `AGENTS.md` or global `~/.codex/AGENTS.md`:

```
Tier: 1
Recipe: new-application

Build a [your app — 2–5 sentences].
```

Act as **eng-orchestrator** — read `SPECFORGE_HOME/ENGINEERING-RECIPES.md`, delegate with file paths only.

### Claude Code

Invoke agents by name (e.g. `eng-orchestrator`) or paste the same tier/recipe template. Skills load from `~/.claude/skills/`.

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

## Gate checkpoint (manual — Codex / OpenCode / Claude)

Cursor hooks automate this; other tools follow the same checklist manually at each gate:

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

## Next up — GitHub Copilot

**First platform on the roadmap after the four supported tools.** See [`ROADMAP.md`](ROADMAP.md#next-up--github-copilot-phase-2).

Planned deliverables:

- `scripts/install-copilot.sh` → `~/.github/agents/`, `~/.github/skills/`
- Bootstrap `--platform copilot` → project `.github/agents/`, `.github/skills/`
- Project `AGENTS.md` as entry; manual gate checkpoints (like Claude/Codex)

Community: PRs and issue `[platform] GitHub Copilot install adapter` welcome.

## Community — other platforms (after Copilot)

**ForgeCode, Aider, Windsurf, Cline, Kiro**, and others are **not shipped yet**. We welcome PRs for `scripts/install-<tool>.sh` and bootstrap overlays once Copilot lands or in parallel if unblocked.

Contribution checklist: [`ROADMAP.md`](ROADMAP.md)

## Hook parity (planned)

- Codex: checkpoint hooks in `.codex/hooks/`
- OpenCode: evaluate plugin lifecycle API
- Same semantics as Cursor [`hooks/scripts/`](../hooks/scripts/)
