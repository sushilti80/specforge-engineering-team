#!/usr/bin/env bash
# Install SpecForge Engineering Team for OpenCode.
# Usage: bash scripts/install-opencode.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/specforge-install.sh
source "$SCRIPT_DIR/lib/specforge-install.sh"

PLUGIN_ROOT="$(specforge_resolve_root)"
OPENCODE_HOME="${OPENCODE_HOME:-$HOME/.config/opencode}"
SPECFORGE_DOCS_DIR="$OPENCODE_HOME/specforge"

echo "Installing SpecForge Engineering Team (OpenCode) from: $PLUGIN_ROOT"

link_agents "$OPENCODE_HOME/agents" "$PLUGIN_ROOT"
link_skills "$OPENCODE_HOME/skills" "$PLUGIN_ROOT"
link_commands "$OPENCODE_HOME/commands" "$PLUGIN_ROOT"
link_docs "$SPECFORGE_DOCS_DIR" "$PLUGIN_ROOT"

chmod +x "$PLUGIN_ROOT/scripts/"*.sh 2>/dev/null || true
chmod +x "$PLUGIN_ROOT/templates/spec-driven-app/scripts/"*.sh 2>/dev/null || true

echo ""
echo "OpenCode install complete."
echo "  Agents:   $OPENCODE_HOME/agents/"
echo "  Skills:   $OPENCODE_HOME/skills/"
echo "  Commands: $OPENCODE_HOME/commands/"
echo "  Docs:     $SPECFORGE_DOCS_DIR/  (SPECFORGE_HOME for OpenCode)"
echo ""
echo "Bootstrap a project:"
echo "  bash $PLUGIN_ROOT/scripts/bootstrap-project.sh /path/to/project"
echo ""
echo "Start work (OpenCode):"
echo "  /spec-pipeline   or   @eng-orchestrator"
echo ""
