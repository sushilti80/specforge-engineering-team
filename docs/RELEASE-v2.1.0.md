# SpecForge Engineering Team v2.1.0

**Release date:** 2026-07-13  
**Type:** Minor (multi-platform hook parity + Copilot + ForgeCode adapters)  
**Previous:** [v2.0.2](https://github.com/sushilti80/specforge-engineering-team/releases/tag/v2.0.2)

## Summary

Extends SpecForge across six coding harnesses. Claude and Codex get global checkpoint hooks via a shared bridge; GitHub Copilot ships as a full adapter (CLI + Cloud Agent); ForgeCode ships as an agents/skills adapter with symlink install and `id:` frontmatter compatibility.

## What's new

### Hook parity (Claude + Codex)

- `hooks/adapters/bridge.py` — normalizes platform hook I/O to the Cursor-shaped core scripts
- `install-claude.sh` → merges 5 hooks into `~/.claude/settings.json`
- `install-codex.sh` → merges 5 hooks into `~/.codex/hooks.json` (trust via `/hooks`)
- `scripts/test-hooks-adapters.sh` — bridge fixtures + idempotent install smoke tests

### GitHub Copilot adapter (CLI + Cloud)

- `scripts/install-copilot.sh` → `~/.copilot/agents/*.agent.md`, `~/.copilot/hooks/specforge.json`
- `bootstrap-project.sh --platform copilot` → vendors `.github/agents/`, `.github/skills/`, `.github/hooks/`, `scripts/specforge-hooks/` (cloud-safe relative paths)
- `bridge.py --platform copilot` — flat `additionalContext` / `decision:block` output
- `templates/platform/AGENTS.copilot.md`
- `scripts/test-copilot-adapter.sh`

### ForgeCode adapter (agents + skills)

- `scripts/install-forge.sh` → symlinks `agents/*.md` to `~/.forge/agents/`, skills to `~/.agents/skills/`
- All 20 agents carry `id:` alongside `name:` (ForgeCode requires `id`; other platforms ignore it)
- `bootstrap-project.sh --platform forge` → `.forge/agents/` + `.forge/commands/` symlinks
- `templates/platform/AGENTS.forge.md` (manual gate checklist — ForgeCode user hooks not merged upstream)
- `scripts/test-forge-adapter.sh`

### Docs + install wiring

- `install-all.sh` now installs Cursor, Claude, Codex, Copilot, ForgeCode, and OpenCode
- `docs/MULTI-TOOL.md` and `docs/ROADMAP.md` updated for six-platform parity matrix
- `README.md` — Options F (Copilot), G (ForgeCode), hook parity sections

## Upgrade

```bash
cd specforge-engineering-team
git pull
bash scripts/install-all.sh
```

Platform-specific:

```bash
bash scripts/install-claude.sh    # hooks → ~/.claude/settings.json
bash scripts/install-codex.sh     # hooks → ~/.codex/hooks.json (then /hooks → trust)
bash scripts/install-copilot.sh   # agents + hooks → ~/.copilot/
bash scripts/install-forge.sh     # agents → ~/.forge/agents/ (restart Forge after install)
```

Bootstrap existing projects:

```bash
bash scripts/bootstrap-project.sh --platform copilot /path/to/project   # cloud-safe vendoring
bash scripts/bootstrap-project.sh --platform forge /path/to/project    # .forge/ symlinks
```

## Hook parity snapshot

| Platform | Hooks |
|----------|-------|
| Cursor | 5 (plugin) |
| Claude Code | 5 (global) |
| Codex CLI | 5 (global) |
| Copilot CLI + Cloud | 5 |
| ForgeCode | manual checklist (upstream hooks pending) |
| OpenCode | manual checklist |

## Tests

```bash
bash scripts/test-hooks-adapters.sh
bash scripts/test-copilot-adapter.sh
bash scripts/test-forge-adapter.sh
```
