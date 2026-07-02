#!/usr/bin/env bash
# Heuristic token estimate for a SpecForge recipe (Tier C — see ENGINEERING-METRICS.md).
# Usage: bash scripts/estimate-pipeline-tokens.sh <recipe> [--tier 0|1|2|3]
set -euo pipefail

RECIPE="${1:-}"
TIER=1

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tier)
      TIER="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$RECIPE" ]]; then
  echo "Usage: bash scripts/estimate-pipeline-tokens.sh <recipe> [--tier 0|1|2|3]" >&2
  echo "Recipes: hotfix bug-fix maintenance greenfield-feature new-application spec-only infra-change security-patch" >&2
  exit 1
fi

# Per-agent baseline: input output (tokens, single pass ~3 turns)
python3 - "$RECIPE" "$TIER" <<'PY'
import sys

recipe = sys.argv[1]
tier = int(sys.argv[2])

# input, output per agent (approximate)
AGENTS = {
    "requirements-analyst": (8000, 3000),
    "challenger": (6000, 2000),
    "architect": (12000, 5000),
    "backend-engineer": (15000, 8000),
    "frontend-engineer": (15000, 8000),
    "fullstack-engineer": (18000, 9000),
    "qa-engineer": (7000, 3000),
    "test-runner": (10000, 2000),
    "code-reviewer": (8000, 2000),
    "security-reviewer": (10000, 2000),
    "ponytail-review": (6000, 1000),
    "verifier": (10000, 3000),
    "spec-guardian": (8000, 2000),
    "eng-orchestrator": (20000, 4000),
    "debugger": (8000, 2000),
    "platform-engineer": (12000, 5000),
    "sre-devops": (10000, 3000),
}

RECIPES = {
    "hotfix": ["eng-orchestrator", "debugger", "backend-engineer", "test-runner", "verifier"],
    "bug-fix": ["eng-orchestrator", "debugger", "backend-engineer", "test-runner", "code-reviewer", "verifier", "spec-guardian"],
    "maintenance": ["eng-orchestrator", "architect", "challenger", "backend-engineer", "test-runner", "code-reviewer", "spec-guardian"],
    "security-patch": ["eng-orchestrator", "backend-engineer", "test-runner", "security-reviewer", "verifier"],
    "infra-change": ["eng-orchestrator", "architect", "platform-engineer", "sre-devops", "test-runner", "verifier"],
    "spec-only": ["eng-orchestrator", "requirements-analyst", "challenger", "architect"],
    "greenfield-feature": [
        "eng-orchestrator", "requirements-analyst", "challenger", "architect", "challenger",
        "backend-engineer", "frontend-engineer", "qa-engineer", "test-runner",
        "code-reviewer", "security-reviewer", "ponytail-review", "verifier", "spec-guardian",
    ],
    "new-application": [
        "eng-orchestrator", "requirements-analyst", "challenger", "architect", "challenger",
        "fullstack-engineer", "qa-engineer", "test-runner",
        "code-reviewer", "security-reviewer", "ponytail-review", "verifier", "spec-guardian",
        "requirements-analyst", "challenger", "architect", "fullstack-engineer", "test-runner", "verifier",
    ],
}

TIER_MULT = {0: 0.3, 1: 1.0, 2: 1.3, 3: 1.6}

if recipe not in RECIPES:
    print(f"Unknown recipe: {recipe}", file=sys.stderr)
    sys.exit(1)

agents = RECIPES[recipe]
ti = to = 0
by_agent = {}
for a in agents:
    inp, out = AGENTS.get(a, (10000, 3000))
    ti += inp
    to += out
    by_agent[a] = by_agent.get(a, 0) + 1

mult = TIER_MULT.get(tier, 1.0)
ti = int(ti * mult)
to = int(to * mult)
total = ti + to

print(f"# Token estimate (heuristic) — recipe={recipe} tier={tier}")
print(f"# Confidence: medium (±30–50%). See SPECFORGE_HOME/ENGINEERING-METRICS.md")
print()
print(f"estimated_input:  {ti:,}")
print(f"estimated_output: {to:,}")
print(f"estimated_total:  {total:,}")
print(f"subagent_passes:  {len(agents)}")
print(f"unique_agents:    {len(by_agent)}")
print()
print("by_agent:")
for a, n in sorted(by_agent.items()):
    inp, out = AGENTS[a]
    print(f"  {a}: {n}x  (~{inp*n:,} in / ~{out*n:,} out)")
print()
print("# Adjustments: context-mode −20–40% effective input; long parent chat +50–200%; Principle 8 checkpoints −30–50% on late gates")
PY
