#!/usr/bin/env bash
# Aggregate release efficiency proxies from git + metrics ledger + gate files.
# Usage: bash scripts/collect-release-metrics.sh [--since TAG] [--project DIR]
set -euo pipefail

SINCE=""
PROJECT="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since)
      SINCE="$2"
      shift 2
      ;;
    --project)
      PROJECT="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: bash scripts/collect-release-metrics.sh [--since TAG] [--project DIR]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

cd "$PROJECT"
GIT_RANGE=""
if [[ -n "$SINCE" ]]; then
  GIT_RANGE="${SINCE}..HEAD"
fi

echo "# SpecForge release metrics (proxies)"
echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# Git diff stat
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "## Git diff"
  if [[ -n "$GIT_RANGE" ]] && git rev-parse "$SINCE" >/dev/null 2>&1; then
    git diff --shortstat "$GIT_RANGE" 2>/dev/null || echo "  (no diff)"
    echo "  range: $GIT_RANGE"
  else
    git diff --shortstat HEAD~20..HEAD 2>/dev/null || echo "  (no diff — pass --since TAG)"
  fi
  echo ""
fi

# Gate checkpoints
echo "## Gate checkpoints"
if [[ -d .specs/handoffs ]]; then
  find .specs/handoffs -name 'GATE-*.md' 2>/dev/null | wc -l | xargs echo "  count:"
  find .specs/handoffs -name 'GATE-*.md' 2>/dev/null | tail -5 | sed 's/^/  /'
else
  echo "  count: 0 (.specs/handoffs/ missing)"
fi
echo ""

# Session ledger
LEDGER=".agents/memory/_project/metrics/session.jsonl"
if [[ ! -f "$LEDGER" && -f .cursor/agent-memory/_project/metrics/session.jsonl ]]; then
  LEDGER=".cursor/agent-memory/_project/metrics/session.jsonl"
fi

echo "## Subagent runs (session.jsonl)"
if [[ -f "$LEDGER" ]]; then
  echo "  ledger: $LEDGER"
  echo "  total events: $(wc -l < "$LEDGER" | tr -d ' ')"
  echo "  by agent:"
  python3 - "$LEDGER" <<'PY'
import json, sys
from collections import Counter
path = sys.argv[1]
c = Counter()
with open(path, encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            o = json.loads(line)
        except json.JSONDecodeError:
            continue
        if o.get("event") == "subagent_complete":
            c[o.get("agent", "?")] += 1
for agent, n in sorted(c.items(), key=lambda x: (-x[1], x[0])):
    print(f"    {agent}: {n}")
PY
else
  echo "  (no ledger — enable Cursor plugin hooks on bootstrapped project)"
fi
echo ""

# REQs in index
echo "## Specs index"
if [[ -f .agents/memory/_project/specs-index.md ]]; then
  echo "  path: .agents/memory/_project/specs-index.md"
  grep -c 'REQ-' .agents/memory/_project/specs-index.md 2>/dev/null | xargs echo "  req mentions:" || true
else
  echo "  (specs-index.md not found)"
fi
echo ""
echo "# Next: bash scripts/estimate-pipeline-tokens.sh <recipe> --tier N"
echo "# Then: skill spec-release-metrics → .specs/metrics/releases/REL-*.yaml"
