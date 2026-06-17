# SpecForge Engineering Team

**SpecForge** is an installable spec-driven engineering team for **Cursor** and **Claude Code**: 20 agents, 9 skills, checkpoint hooks, project memory, and a bootstrap template.

> Specs are source of truth. Chat is ephemeral. Memory learns on disk.

## Install

### Option A — Both platforms

```bash
git clone https://github.com/sushilti80/specforge-engineering-team-.git
cd specforge-engineering-team
bash scripts/install-all.sh
```

### Option B — Cursor only

```bash
bash scripts/install.sh
```

Restart Cursor → **Settings → Plugins** → enable **specforge-engineering-team**.

### Option C — Claude Code only

```bash
bash scripts/install-claude.sh
```

Symlinks agents/skills into `~/.claude/`.

### Bootstrap a project

```bash
bash scripts/bootstrap-project.sh /path/to/your-app
```

Commit `.specs/` and `.cursor/agent-memory/` to git.

## First prompt

```
/spec-pipeline

Tier: 1
Recipe: new-application

Build a [your app — 2–5 sentences].
```

## What's included

| Component | Count | Purpose |
|-----------|-------|---------|
| **Agents** | 20 | Orchestrator, analysts, implementers, QA, reviewers, verifier, challenger |
| **Skills** | 9 | Pipeline, recipes, handoffs, memory, REQ/ARCH, challenger, verifier, drift |
| **Rules** | 2 | Spec gates + agent memory |
| **Commands** | 3 | `/spec-pipeline`, `/eng-orchestrator`, `/bootstrap-spec-project` |
| **Hooks** | 4 | Session context, gate checkpoint, learning journal, session-end reminder |
| **Docs** | 4 | Playbook, recipes, bootstrap guide, executive summary |

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

## Self-learning (hooks)

When the Cursor plugin is enabled on a bootstrapped project:

1. **`afterFileEdit`** → logs `.specs/` and memory edits to `learning-journal.md`
2. **`sessionStart`** → injects Principle 8 context + recent journal
3. **`subagentStop`** → checkpoint reminder at gate boundaries
4. **`stop`** → nudges memory distillation

## Repository layout

```
specforge-engineering-team/
├── .cursor-plugin/plugin.json
├── agents/
├── skills/
├── rules/
├── commands/
├── hooks/
├── docs/
├── templates/spec-driven-app/
└── scripts/
    ├── install.sh          # Cursor
    ├── install-claude.sh   # Claude Code
    ├── install-all.sh      # Both
    └── bootstrap-project.sh
```

## Publish / marketplace

- **Cursor:** submit at [cursor.com/marketplace/publish](https://cursor.com/marketplace/publish)
- **Claude:** distribute via this repo; users run `install-claude.sh`
- **Artifacts:** clone or download release tarball; run install scripts

## License

MIT — see [LICENSE](LICENSE)
