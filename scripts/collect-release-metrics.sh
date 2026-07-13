#!/usr/bin/env bash
# Aggregate release efficiency proxies from git + metrics ledger + gate files.
# Usage: bash scripts/collect-release-metrics.sh [--since TAG|COMMIT] [--project DIR]
#
# Ledger fidelity needs SpecForge hooks (Cursor plugin, or Claude/Codex/Copilot
# adapters). Forge/OpenCode do not write session.jsonl — git/gates still work.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bash scripts/collect-release-metrics.sh [options]

Options:
  --since TAG|COMMIT   Git range start (TAG..HEAD). Required for meaningful diffs.
                       Also filters session.jsonl to events at/after that commit's time.
  --project DIR        Project root (default: .)
  -h, --help           Show this help

Examples:
  bash scripts/collect-release-metrics.sh --since v1.2.0
  bash scripts/collect-release-metrics.sh --since abc1234 --project /path/to/app
EOF
}

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
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

cd "$PROJECT"

SINCE_ISO=""
GIT_RANGE=""
IN_GIT=0
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  IN_GIT=1
fi

# Fail early on bad --since (before any report output)
if [[ -n "$SINCE" ]]; then
  if [[ "$IN_GIT" -ne 1 ]]; then
    echo "ERROR: --since requires a git repository (cwd: $(pwd))" >&2
    exit 1
  fi
  if ! git rev-parse --verify "$SINCE" >/dev/null 2>&1; then
    echo "ERROR: --since '$SINCE' is not a valid git ref in $(pwd)" >&2
    echo "Hint: use an app release tag/commit, not a SpecForge harness tag." >&2
    exit 1
  fi
  GIT_RANGE="${SINCE}..HEAD"
  SINCE_ISO="$(git log -1 --format=%cI "$SINCE" 2>/dev/null || true)"
fi

echo "# SpecForge release metrics (proxies)"
echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "# Project: $(pwd)"
echo ""

if [[ "$IN_GIT" -eq 1 ]]; then
  echo "## Git diff"
  if [[ -n "$SINCE" ]]; then
    if git diff --shortstat "$GIT_RANGE" 2>/dev/null; then
      :
    else
      echo "  (no diff)"
    fi
    echo "  range: $GIT_RANGE"
    if [[ -n "$SINCE_ISO" ]]; then
      echo "  since_commit_time: $SINCE_ISO"
    fi
  else
    # Prefer a bounded recent window that actually exists
    FALLBACK_N=20
    DEPTH="$(git rev-list --count HEAD 2>/dev/null || echo 0)"
    if [[ "$DEPTH" -le 1 ]]; then
      echo "  (no prior commits — pass --since TAG for a meaningful range)"
    else
      if [[ "$DEPTH" -le "$FALLBACK_N" ]]; then
        FALLBACK_N=$((DEPTH - 1))
      fi
      git diff --shortstat "HEAD~${FALLBACK_N}..HEAD" 2>/dev/null || echo "  (no diff)"
      echo "  range: HEAD~${FALLBACK_N}..HEAD (default; pass --since TAG for release bounds)"
      SINCE_ISO="$(git log -1 --format=%cI "HEAD~${FALLBACK_N}" 2>/dev/null || true)"
    fi
  fi
  echo ""
else
  echo "## Git diff"
  echo "  (not a git repository)"
  echo ""
fi

# Gate checkpoints
echo "## Gate checkpoints"
if [[ -d .specs/handoffs ]]; then
  GATE_COUNT="$(find .specs/handoffs -name 'GATE-*.md' 2>/dev/null | wc -l | tr -d ' ')"
  echo "  count: $GATE_COUNT"
  find .specs/handoffs -name 'GATE-*.md' 2>/dev/null | sort | tail -5 | sed 's/^/  /'
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
  python3 - "$LEDGER" "${SINCE_ISO:-}" <<'PY'
import json, sys
from collections import Counter
from datetime import datetime, timezone

path, since_iso = sys.argv[1], sys.argv[2]


def parse_ts(s):
    if not s:
        return None
    s = s.strip()
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    try:
        dt = datetime.fromisoformat(s)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


since_dt = parse_ts(since_iso) if since_iso else None
c = Counter()
total = 0
in_range = 0
skipped_ts = 0

with open(path, encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            o = json.loads(line)
        except json.JSONDecodeError:
            continue
        if o.get("event") != "subagent_complete":
            continue
        total += 1
        if since_dt is not None:
            ev_dt = parse_ts(str(o.get("ts") or ""))
            if ev_dt is None:
                skipped_ts += 1
                continue
            if ev_dt < since_dt:
                continue
        in_range += 1
        c[o.get("agent", "?")] += 1

if since_dt is not None:
    print(f"  events_in_range: {in_range} (of {total} total; filtered ts >= {since_iso})")
    if skipped_ts:
        print(f"  skipped_missing_ts: {skipped_ts}")
else:
    print(f"  total events: {total}")

if not c:
    print("  by agent: (none in range)")
else:
    print("  by agent:")
    for agent, n in sorted(c.items(), key=lambda x: (-x[1], x[0])):
        print(f"    {agent}: {n}")
PY
else
  cat <<'EOF'
  (no ledger found)
  Enable SpecForge hooks so subagent_complete events are written:
    - Cursor: plugin hooks on a bootstrapped project
    - Claude / Codex / Copilot: install-* + bridge adapters (or project bootstrap)
  Forge / OpenCode: no user hooks — ledger stays empty; git + gates above still apply.
EOF
fi
echo ""

# REQs in index
echo "## Specs index"
if [[ -f .agents/memory/_project/specs-index.md ]]; then
  echo "  path: .agents/memory/_project/specs-index.md"
  REQ_N="$(grep -c 'REQ-' .agents/memory/_project/specs-index.md 2>/dev/null || true)"
  echo "  req mentions: ${REQ_N:-0}"
elif [[ -f .cursor/agent-memory/_project/specs-index.md ]]; then
  echo "  path: .cursor/agent-memory/_project/specs-index.md"
  REQ_N="$(grep -c 'REQ-' .cursor/agent-memory/_project/specs-index.md 2>/dev/null || true)"
  echo "  req mentions: ${REQ_N:-0}"
else
  echo "  (specs-index.md not found)"
fi
echo ""
echo "# Next: bash scripts/estimate-pipeline-tokens.sh <recipe> --tier N [--agents a,b,c]"
echo "# Then: skill spec-release-metrics → .specs/metrics/releases/REL-*.yaml"
