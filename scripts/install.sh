#!/usr/bin/env bash
# Install SpecForge Engineering Team for Cursor (local plugin + doc symlinks).
# Usage: bash scripts/install.sh [optional-plugin-source-dir]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE="${1:-$PLUGIN_ROOT}"
CURSOR_HOME="${CURSOR_HOME:-$HOME/.cursor}"
LOCAL_PLUGIN="$CURSOR_HOME/plugins/local/specforge-engineering-team"

echo "Installing SpecForge Engineering Team (Cursor) from: $SOURCE"

mkdir -p "$CURSOR_HOME/plugins/local"
ln -sfn "$SOURCE" "$LOCAL_PLUGIN"
echo "Linked: $LOCAL_PLUGIN -> $SOURCE"

for doc in ENGINEERING-PLAYBOOK.md ENGINEERING-RECIPES.md BOOTSTRAP-SPEC-DRIVEN-PROJECT.md SPEC-DRIVEN-EXECUTIVE-SUMMARY.md; do
  if [[ -f "$SOURCE/docs/$doc" ]]; then
    ln -sfn "$SOURCE/docs/$doc" "$CURSOR_HOME/$doc"
    echo "Linked: $CURSOR_HOME/$doc"
  fi
done

chmod +x "$LOCAL_PLUGIN/hooks/scripts/"* 2>/dev/null || true
chmod +x "$LOCAL_PLUGIN/scripts/"*.sh 2>/dev/null || true
chmod +x "$LOCAL_PLUGIN/templates/spec-driven-app/scripts/"*.sh 2>/dev/null || true

echo ""
echo "Cursor install complete."
echo "  1. Restart Cursor"
echo "  2. Settings → Plugins → enable 'specforge-engineering-team'"
echo "  3. bash $LOCAL_PLUGIN/scripts/bootstrap-project.sh /path/to/project"
echo "  4. Agent: /spec-pipeline  Tier: 1  Recipe: new-application"
echo ""
