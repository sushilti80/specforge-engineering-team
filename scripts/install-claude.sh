#!/usr/bin/env bash
# Install SpecForge Engineering Team for Claude Code (agents + skills + docs).
# Usage: bash scripts/install-claude.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/specforge-install.sh
source "$SCRIPT_DIR/lib/specforge-install.sh"

PLUGIN_ROOT="$(specforge_resolve_root)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
SPECFORGE_DOCS_DIR="$CLAUDE_HOME/docs/specforge"

echo "Installing SpecForge Engineering Team for Claude from: $PLUGIN_ROOT"

link_agents "$CLAUDE_HOME/agents" "$PLUGIN_ROOT"
link_skills "$CLAUDE_HOME/skills" "$PLUGIN_ROOT"
link_docs "$SPECFORGE_DOCS_DIR" "$PLUGIN_ROOT"

echo ""
echo "Claude install complete."
echo "  Agents: $CLAUDE_HOME/agents/"
echo "  Skills: $CLAUDE_HOME/skills/"
echo "  Docs:   $SPECFORGE_DOCS_DIR/  (SPECFORGE_HOME for Claude)"
echo ""
echo "Bootstrap a project:"
echo "  bash $PLUGIN_ROOT/scripts/bootstrap-project.sh /path/to/project"
echo ""
