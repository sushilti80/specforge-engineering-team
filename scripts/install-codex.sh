#!/usr/bin/env bash
# Install SpecForge Engineering Team for OpenAI Codex CLI.
# Usage: bash scripts/install-codex.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/specforge-install.sh
source "$SCRIPT_DIR/lib/specforge-install.sh"

PLUGIN_ROOT="$(specforge_resolve_root)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
AGENTS_SKILLS_HOME="${AGENTS_SKILLS_HOME:-$HOME/.agents/skills}"
SPECFORGE_DOCS_DIR="$CODEX_HOME/specforge"
AGENTS_MD_TEMPLATE="$PLUGIN_ROOT/templates/platform/AGENTS.codex.md"
AGENTS_MD_TARGET="$CODEX_HOME/AGENTS.md"

echo "Installing SpecForge Engineering Team (Codex) from: $PLUGIN_ROOT"

link_skills "$AGENTS_SKILLS_HOME" "$PLUGIN_ROOT"
link_docs "$SPECFORGE_DOCS_DIR" "$PLUGIN_ROOT"
install_agents_md "$AGENTS_MD_TARGET" "$AGENTS_MD_TEMPLATE"
install_codex_hooks "$CODEX_HOME" "$PLUGIN_ROOT"

chmod +x "$PLUGIN_ROOT/scripts/"*.sh 2>/dev/null || true
chmod +x "$PLUGIN_ROOT/templates/spec-driven-app/scripts/"*.sh 2>/dev/null || true

echo ""
echo "Codex install complete."
echo "  Skills:  $AGENTS_SKILLS_HOME/"
echo "  Docs:    $SPECFORGE_DOCS_DIR/  (SPECFORGE_HOME for Codex)"
echo "  Global:  $AGENTS_MD_TARGET"
echo "  Hooks:   $CODEX_HOME/hooks.json (5 SpecForge checkpoint hooks)"
echo ""
echo "Trust hooks (required once after install/change):"
echo "  Codex CLI → /hooks → trust SpecForge entries"
echo ""
echo "Bootstrap a project:"
echo "  bash $PLUGIN_ROOT/scripts/bootstrap-project.sh /path/to/project"
echo ""
echo "Start work (Codex CLI):"
echo "  Recipe: new-application | Tier: 1"
echo "  Read AGENTS.md, then act as eng-orchestrator using SPECFORGE_HOME/specforge/ENGINEERING-RECIPES.md"
echo ""
