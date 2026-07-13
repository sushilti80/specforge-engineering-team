#!/usr/bin/env bash
# Install SpecForge Engineering Team for GitHub Copilot (CLI global).
# Usage: bash scripts/install-copilot.sh
#
# Cloud Agent users: do NOT run this for cloud Copilot. Cloud runners cannot
# read $HOME. Use bootstrap-project.sh --platform copilot instead, which
# vendors scripts + hooks into the repo's .github/ directory.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/specforge-install.sh
source "$SCRIPT_DIR/lib/specforge-install.sh"

PLUGIN_ROOT="$(specforge_resolve_root)"
COPILOT_HOME="${COPILOT_HOME:-$HOME/.copilot}"
AGENTS_SKILLS_HOME="${AGENTS_SKILLS_HOME:-$HOME/.agents/skills}"
SPECFORGE_DOCS_DIR="$COPILOT_HOME/specforge"
AGENTS_MD_TEMPLATE="$PLUGIN_ROOT/templates/platform/AGENTS.copilot.md"
AGENTS_MD_TARGET="$COPILOT_HOME/AGENTS.md"

echo "Installing SpecForge Engineering Team (Copilot CLI) from: $PLUGIN_ROOT"

link_copilot_agents "$COPILOT_HOME/agents" "$PLUGIN_ROOT"
link_skills "$AGENTS_SKILLS_HOME" "$PLUGIN_ROOT"
link_docs "$SPECFORGE_DOCS_DIR" "$PLUGIN_ROOT"
install_agents_md "$AGENTS_MD_TARGET" "$AGENTS_MD_TEMPLATE"
install_copilot_hooks "$COPILOT_HOME" "$PLUGIN_ROOT"

chmod +x "$PLUGIN_ROOT/scripts/"*.sh 2>/dev/null || true
chmod +x "$PLUGIN_ROOT/templates/spec-driven-app/scripts/"*.sh 2>/dev/null || true

echo ""
echo "Copilot install complete."
echo "  Agents: $COPILOT_HOME/agents/*.agent.md"
echo "  Skills: $AGENTS_SKILLS_HOME/"
echo "  Docs:   $SPECFORGE_DOCS_DIR/  (SPECFORGE_HOME for Copilot)"
echo "  Global: $AGENTS_MD_TARGET"
echo "  Hooks:  $COPILOT_HOME/hooks/specforge.json (5 SpecForge checkpoint hooks)"
echo ""
echo "Cloud-safe usage (Copilot Cloud Agent cannot read \$HOME):"
echo "  bash $PLUGIN_ROOT/scripts/bootstrap-project.sh --platform copilot /path/to/project"
echo "  → vendors .github/agents, .github/skills, .github/hooks, scripts/specforge-hooks/"
echo ""
echo "Start work (Copilot CLI):"
echo "  Recipe: new-application | Tier: 1"
echo "  Read AGENTS.md, then act as eng-orchestrator using SPECFORGE_HOME/specforge/ENGINEERING-RECIPES.md"
echo ""
