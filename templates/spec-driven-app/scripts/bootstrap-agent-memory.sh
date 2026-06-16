#!/usr/bin/env bash
# Run from project root: bash scripts/bootstrap-agent-memory.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AGENTS=(
  eng-orchestrator requirements-analyst architect challenger adr-recorder
  spec-guardian backend-engineer frontend-engineer fullstack-engineer
  data-engineer mobile-engineer platform-engineer sre-devops
  qa-engineer test-runner code-reviewer security-reviewer verifier debugger
)
for a in "${AGENTS[@]}"; do
  dir="$ROOT/.cursor/agent-memory/$a"
  mkdir -p "$dir"
  [[ -f "$dir/MEMORY.md" ]] || echo -e "# $a memory\n\n## Lessons\n\n- \n" > "$dir/MEMORY.md"
done
echo "Agent memory folders ready under .cursor/agent-memory/"
