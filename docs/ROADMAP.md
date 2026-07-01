# SpecForge roadmap

Last updated: 2026-07-01

## Shipped (supported today)

| Platform | Install | Agents | Skills | Hooks | Ponytail |
|----------|---------|--------|--------|-------|----------|
| **Cursor** | `scripts/install.sh` | 20 (plugin) | 15 | 4 | rule + skills |
| **Claude Code** | `scripts/install-claude.sh` | 20 | 15 | — | skills |
| **Codex CLI** | `scripts/install-codex.sh` | via AGENTS.md | 15 | — | skills |
| **OpenCode** | `scripts/install-opencode.sh` | 20 | 15 | — | skills |

**Ponytail** (vendored from [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail), MIT):

- Six skills: `ponytail`, `ponytail-review`, `ponytail-audit`, `ponytail-debt`, `ponytail-gain`, `ponytail-help`
- Cursor always-on rule: `rules/ponytail.mdc` (bootstrapped into projects)
- Refresh: `bash scripts/sync-ponytail.sh`
- Gate 3: `ponytail-review` runs parallel with `code-reviewer` and `security-reviewer`

---

## Next up — GitHub Copilot (Phase 2)

**Priority #1** after the four supported platforms. Maintainer target; community PRs welcome.

| Deliverable | Target |
|-------------|--------|
| `scripts/install-copilot.sh` | Symlink agents → `~/.github/agents/`, skills → `~/.github/skills/`, docs → `~/.github/specforge/` (or tool-native paths per Copilot docs) |
| Bootstrap | `--platform copilot` → project `.github/agents/`, `.github/skills/` |
| Entry | Project `AGENTS.md` + Copilot custom agents |
| Parity | 20 agents, 15 skills, spec gates; hooks manual (same as Claude/Codex) |

**Stretch:** Copilot-specific agent definitions under `.github/agents/`; ponytail via skills (rule TBD).

Track progress: open issue `[platform] GitHub Copilot install adapter`. Label: `platform`, `copilot`, `next-up`.

---

## Community wanted — additional AI tools

We want **community contributions** for install scripts and bootstrap overlays. SpecForge is one harness (agents, skills, docs); each tool needs a thin adapter.

**Copilot is next on the maintainer roadmap** (above). The table below is for other tools after Copilot, or parallel community work if you are not blocked on Copilot paths.

### Target tools (not yet supported)

| Priority | Tool | Likely install path | Notes | Status |
|----------|------|---------------------|-------|--------|
| **Next** | **GitHub Copilot** | `.github/agents/`, `.github/skills/` | Phase 2 — see [Next up](#next-up--github-copilot-phase-2) | **Next up** |
| 2 | **ForgeCode** | `~/.forge/skills/`, `~/.forge/agents/`, `AGENTS.md` | Agent YAML differs (`id`, `tools:`); manual orchestration | Help wanted |
| 3 | **Aider** | `.aider.conf.yml`, `AGENTS.md`, repo rules | No native subagents; skills → conventions in AGENTS.md | Help wanted |
| 4 | **Windsurf** | `.windsurf/rules/` | Ponytail ships a rules file upstream | Help wanted |
| 5 | **Cline** | `.clinerules/` | Instruction-only | Help wanted |
| 6 | **Kiro** | `.kiro/steering/` | Instruction-only | Help wanted |

### What a good contribution includes

1. **`scripts/install-<tool>.sh`** — symlinks agents, skills, docs to the tool’s discovery paths (use `scripts/lib/specforge-install.sh`)
2. **Bootstrap flag** — extend `scripts/bootstrap-project.sh --platform <tool>` if the tool needs project-local paths
3. **Row in `docs/MULTI-TOOL.md`** — parity matrix + quickstart
4. **Smoke test notes** — how you verified agents/skills load (screenshot or command output)
5. **No fork of core playbook** — reuse `SPECFORGE_HOME` docs; adapt paths only

### Out of scope for v1 adapters

- Reimplementing Cursor hooks (document manual checkpoint checklist instead)
- Converting all 20 agents if the tool only supports AGENTS.md + skills (document reduced mode)
- Vendor-specific model routing

### How to contribute

1. Open an issue: `[platform] install script for <tool>` — describe parity you can achieve
2. Fork → branch `feat/install-<tool>`
3. PR with install script + MULTI-TOOL.md + ROADMAP status update
4. We merge when: install is idempotent, docs are clear, no secrets in repo

Questions: open a GitHub issue with label `platform`.

---

## Planned (maintainers)

| Priority | Item | Description |
|----------|------|-------------|
| **1** | **`install-copilot.sh`** | GitHub Copilot — agents, skills, bootstrap (Phase 2) |
| 2 | Hook parity | Codex / OpenCode lifecycle hooks matching Cursor gate semantics |
| 3 | `simplicity-reviewer` agent | Optional Gate 3 agent (readonly) — or rely on `ponytail-review` skill |
| 4 | Ponytail auto-sync | CI check that `vendor/ponytail/VERSION` matches upstream tag |

---

## Principles (unchanged)

- Specs before code (`.specs/` is source of truth)
- Supported platforms get **real** skill files (not broken symlinks to `vendor/` in bootstrapped projects)
- Third-party skills (Ponytail) stay MIT-attributed under `vendor/ponytail/`
