#!/usr/bin/env bash
# Install SpecForge Engineering Team for Claude Code (agents + skills + docs).
# Usage: bash scripts/install-claude.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

echo "Installing SpecForge Engineering Team for Claude from: $PLUGIN_ROOT"

mkdir -p "$CLAUDE_HOME/agents" "$CLAUDE_HOME/skills"

for agent in "$PLUGIN_ROOT/agents/"*.md; do
  [[ -f "$agent" ]] || continue
  name="$(basename "$agent")"
  ln -sfn "$agent" "$CLAUDE_HOME/agents/$name"
  echo "  agent: $name"
done

for skill_dir in "$PLUGIN_ROOT/skills/"*/; do
  [[ -d "$skill_dir" ]] || continue
  name="$(basename "$skill_dir")"
  ln -sfn "$skill_dir" "$CLAUDE_HOME/skills/$name"
  echo "  skill: $name"
done

mkdir -p "$CLAUDE_HOME/docs/specforge"
for doc in ENGINEERING-PLAYBOOK.md ENGINEERING-RECIPES.md BOOTSTRAP-SPEC-DRIVEN-PROJECT.md SPEC-DRIVEN-EXECUTIVE-SUMMARY.md; do
  if [[ -f "$PLUGIN_ROOT/docs/$doc" ]]; then
    ln -sfn "$PLUGIN_ROOT/docs/$doc" "$CLAUDE_HOME/docs/specforge/$doc"
    echo "  doc: $doc"
  fi
done

echo ""
echo "Claude install complete."
echo "  Agents: $CLAUDE_HOME/agents/"
echo "  Skills: $CLAUDE_HOME/skills/"
echo "  Docs:   $CLAUDE_HOME/docs/specforge/"
echo ""
echo "Bootstrap a project:"
echo "  bash $PLUGIN_ROOT/scripts/bootstrap-project.sh /path/to/project"
echo ""
