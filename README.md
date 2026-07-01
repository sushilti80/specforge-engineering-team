# SpecForge Engineering Team

**SpecForge** is an installable spec-driven engineering team for **Cursor**, **Claude Code**, **Codex CLI**, and **OpenCode**: 20 agents, 15 skills (9 spec + 6 ponytail), checkpoint hooks (Cursor), project memory, and a bootstrap template.

> Specs are source of truth. Chat is ephemeral. Memory learns on disk.

## Install

### Option A — All platforms (recommended)

```bash
git clone https://github.com/sushilti80/specforge-engineering-team-.git
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

### Bootstrap a project

```bash
bash scripts/bootstrap-project.sh /path/to/your-app
```

Commit `.specs/`, `.agents/memory/`, and `AGENTS.md` to git. Bootstrapped Cursor projects include the **ponytail** always-on rule (minimal code ladder).

## First prompt

**Cursor / OpenCode:**

```
/spec-pipeline

Tier: 1
Recipe: new-application

Build a [your app — 2–5 sentences].
```

**Codex / Claude:** use the same tier/recipe block — see project `AGENTS.md`.

## What's included

| Component | Count | Purpose |
|-----------|-------|---------|
| **Agents** | 20 | Orchestrator, analysts, implementers, QA, reviewers, verifier, challenger |
| **Spec skills** | 9 | Pipeline, recipes, handoffs, memory, REQ/ARCH, challenger, verifier, drift |
| **Ponytail skills** | 6 | Minimal code ladder, diff/repo bloat review, debt ledger ([upstream](https://github.com/DietrichGebert/ponytail)) |
| **Rules** | 3 | Spec gates, agent memory, ponytail (Cursor) |
| **Commands** | 3 | `/spec-pipeline`, `/eng-orchestrator`, `/bootstrap-spec-project` |
| **Hooks** | 4 | Session context, gate checkpoint, learning journal, session-end (Cursor) |
| **Docs** | 6 | Playbook, recipes, bootstrap, executive summary, multi-tool, roadmap |

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

`new-application` · `greenfield-feature` · `bug-fix` · `hotfix` · `maintenance` · `infra-change` · `spec-only` · `security-patch`

See `docs/ENGINEERING-RECIPES.md`.

## Self-learning (Cursor hooks)

When the Cursor plugin is enabled on a bootstrapped project:

1. **`afterFileEdit`** → logs `.specs/` and memory edits to `learning-journal.md`
2. **`sessionStart`** → injects Principle 8 context + recent journal
3. **`subagentStop`** → checkpoint reminder at gate boundaries
4. **`stop`** → nudges memory distillation

Other tools: follow the manual checkpoint checklist in `docs/MULTI-TOOL.md`.

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
│   ├── spec-*              # 9 spec-driven skills
│   └── ponytail*           # 6 ponytail skills (synced from upstream)
├── rules/                  # Cursor plugin rules (+ ponytail.mdc)
├── commands/
├── hooks/
├── docs/
│   └── ROADMAP.md          # platform parity + community contributions
├── vendor/ponytail/        # upstream attribution (LICENSE, VERSION)
├── templates/
│   ├── platform/AGENTS.codex.md
│   └── spec-driven-app/    # bootstrap template (includes ponytail rule)
└── scripts/
    ├── install.sh           # Cursor
    ├── install-claude.sh    # Claude Code
    ├── install-codex.sh     # Codex CLI
    ├── install-opencode.sh  # OpenCode
    ├── install-all.sh       # All supported platforms
    ├── sync-ponytail.sh     # Refresh ponytail from GitHub
    ├── lib/specforge-install.sh
    └── bootstrap-project.sh
```

## License

MIT — see [LICENSE](LICENSE). Ponytail skills are MIT — see [vendor/ponytail/LICENSE](vendor/ponytail/LICENSE).
