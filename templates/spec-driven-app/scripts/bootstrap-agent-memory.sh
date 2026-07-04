#!/usr/bin/env bash
# Run from project root: bash scripts/bootstrap-agent-memory.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MEMORY_ROOT="$ROOT/.agents/memory"
AGENTS=(
  eng-orchestrator requirements-analyst architect challenger adr-recorder
  spec-guardian backend-engineer frontend-engineer fullstack-engineer
  data-engineer mobile-engineer platform-engineer sre-devops
  qa-engineer test-runner code-reviewer security-reviewer verifier debugger
  tech-lead
)
mkdir -p "$MEMORY_ROOT"
for a in "${AGENTS[@]}"; do
  dir="$MEMORY_ROOT/$a"
  mkdir -p "$dir"
  [[ -f "$dir/MEMORY.md" ]] || echo -e "# $a memory\n\n## Lessons\n\n- \n" > "$dir/MEMORY.md"
done
# Cursor compat symlink
if [[ ! -e "$ROOT/.cursor/agent-memory" && -d "$MEMORY_ROOT" ]]; then
  mkdir -p "$ROOT/.cursor"
  ln -sfn "../.agents/memory" "$ROOT/.cursor/agent-memory"
fi
echo "Agent memory folders ready under .agents/memory/"
