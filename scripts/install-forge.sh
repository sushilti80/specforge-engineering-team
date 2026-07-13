#!/usr/bin/env bash
# Install SpecForge Engineering Team for ForgeCode (agents + skills + docs).
# Usage: bash scripts/install-forge.sh
#
# Note: ForgeCode has no user-configurable hooks yet (PR #2757 was closed
# 2026-04-28 without merging). Gate checkpoints are a manual checklist here,
# same parity tier as OpenCode. When ForgeCode ships user hooks, add a
# `install_forge_hooks` helper + hooks/forge/ fragment + bridge.py alias.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/specforge-install.sh
source "$SCRIPT_DIR/lib/specforge-install.sh"

PLUGIN_ROOT="$(specforge_resolve_root)"
FORGE_HOME="${FORGE_HOME:-$HOME/.forge}"
AGENTS_SKILLS_HOME="${AGENTS_SKILLS_HOME:-$HOME/.agents/skills}"
SPECFORGE_DOCS_DIR="$FORGE_HOME/specforge"
AGENTS_MD_TEMPLATE="$PLUGIN_ROOT/templates/platform/AGENTS.forge.md"
AGENTS_MD_TARGET="$FORGE_HOME/AGENTS.md"

echo "Installing SpecForge Engineering Team for ForgeCode from: $PLUGIN_ROOT"

# ForgeCode reads ~/forge/agents/*.md (plain .md, body-as-prompt).
# SpecForge agents carry both `name:` (Cursor/Claude) and `id:` (ForgeCode).
link_agents "$FORGE_HOME/agents" "$PLUGIN_ROOT"
link_skills "$AGENTS_SKILLS_HOME" "$PLUGIN_ROOT"
link_docs "$SPECFORGE_DOCS_DIR" "$PLUGIN_ROOT"
install_agents_md "$AGENTS_MD_TARGET" "$AGENTS_MD_TEMPLATE"

chmod +x "$PLUGIN_ROOT/scripts/"*.sh 2>/dev/null || true
chmod +x "$PLUGIN_ROOT/templates/spec-driven-app/scripts/"*.sh 2>/dev/null || true

echo ""
echo "ForgeCode install complete."
echo "  Agents: $FORGE_HOME/agents/*.md  (20 agents, each with \`id:\` + \`name:\`)"
echo "  Skills: $AGENTS_SKILLS_HOME/     (ForgeCode has no native skills path; load on demand via AGENTS.md)"
echo "  Docs:   $SPECFORGE_DOCS_DIR/     (SPECFORGE_HOME for ForgeCode)"
echo "  Global: $AGENTS_MD_TARGET        (auto-loaded by Forge at conversation start)"
echo "  Hooks:  none (ForgeCode user hooks not yet merged upstream — manual gate checklist)"
echo ""
echo "Restart ForgeCode after install so it picks up the new agent files."
echo ""
echo "Bootstrap a project (project-local agents override global):"
echo "  bash $PLUGIN_ROOT/scripts/bootstrap-project.sh --platform forge /path/to/project"
echo ""
echo "Start work (ForgeCode):"
echo "  :agent eng-orchestrator   (or pick via :agent picker)"
echo "  Then paste need/tier block from AGENTS.md (see SPECFORGE_HOME/specforge/ENGINEERING-RECIPES.md)"
echo ""
