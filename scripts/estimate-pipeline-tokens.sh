#!/usr/bin/env bash
# Heuristic token estimate (Tier C — ENGINEERING-METRICS.md).
# Source of truth for *which* agents to run: ENGINEERING-RECIPES.md §0 matrix + HANDOFF Plan.
# Prefer:  --agents from orchestrator agents_planned (exact plan)
# Fallback: --mode minimal|ceiling (approximate lists — may drift; do not treat as matrix SoT)
#
# Usage:
#   bash scripts/estimate-pipeline-tokens.sh <recipe> --tier N --mode minimal
#   bash scripts/estimate-pipeline-tokens.sh <recipe> --tier N --agents eng-orchestrator,requirements-analyst,backend-engineer,test-runner,verifier
set -euo pipefail

RECIPE="${1:-}"
TIER=1
MODE="minimal"
AGENTS_OVERRIDE=""

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tier)
      TIER="$2"
      shift 2
      ;;
    --mode)
      MODE="$2"
      shift 2
      ;;
    --agents)
      AGENTS_OVERRIDE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$RECIPE" ]]; then
  echo "Usage: bash scripts/estimate-pipeline-tokens.sh <recipe> [--tier 0|1|2|3] [--mode minimal|ceiling] [--agents a,b,c]" >&2
  echo "Recipes: hotfix bug-fix maintenance greenfield-feature|capability new-application spec-only infra-change security-patch advisory-only docs-touch vendor-sync" >&2
  exit 1
fi

# Normalize alias
if [[ "$RECIPE" == "capability" || "$RECIPE" == "feature-change" ]]; then
  RECIPE="greenfield-feature"
fi

python3 - "$RECIPE" "$TIER" "$MODE" "$AGENTS_OVERRIDE" <<'PY'
import sys

recipe, tier_s, mode, override = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
tier = int(tier_s)

AGENTS = {
    "requirements-analyst": (8000, 3000),
    "challenger": (6000, 2000),
    "architect": (12000, 5000),
    "adr-recorder": (5000, 2000),
    "backend-engineer": (15000, 8000),
    "frontend-engineer": (15000, 8000),
    "fullstack-engineer": (18000, 9000),
    "mobile-engineer": (15000, 8000),
    "data-engineer": (15000, 8000),
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

# Minimal = matrix R (+ orchestrator). Ceiling = upper-bound historical full lists.
MINIMAL = {
    "hotfix": {
        0: ["eng-orchestrator", "debugger"],
        1: ["eng-orchestrator", "debugger", "backend-engineer", "test-runner", "verifier"],
        2: ["eng-orchestrator", "debugger", "backend-engineer", "test-runner", "verifier"],
        3: ["eng-orchestrator", "debugger", "backend-engineer", "test-runner", "security-reviewer", "verifier"],
    },
    "bug-fix": {
        1: ["eng-orchestrator", "debugger", "backend-engineer", "test-runner", "code-reviewer", "verifier"],
        2: ["eng-orchestrator", "debugger", "backend-engineer", "test-runner", "code-reviewer", "verifier"],
        3: ["eng-orchestrator", "debugger", "backend-engineer", "test-runner", "code-reviewer", "security-reviewer", "verifier"],
    },
    "maintenance": {
        1: ["eng-orchestrator", "adr-recorder", "backend-engineer", "test-runner", "verifier"],
        2: ["eng-orchestrator", "architect", "backend-engineer", "test-runner", "code-reviewer", "verifier", "spec-guardian"],
        3: ["eng-orchestrator", "architect", "challenger", "backend-engineer", "test-runner", "code-reviewer", "security-reviewer", "verifier", "spec-guardian"],
    },
    "security-patch": {
        1: ["eng-orchestrator", "security-reviewer", "backend-engineer", "test-runner", "security-reviewer", "verifier"],
        2: ["eng-orchestrator", "security-reviewer", "backend-engineer", "test-runner", "security-reviewer", "verifier"],
        3: ["eng-orchestrator", "security-reviewer", "backend-engineer", "test-runner", "security-reviewer", "verifier", "spec-guardian"],
    },
    "infra-change": {
        1: ["eng-orchestrator", "architect", "platform-engineer", "test-runner", "verifier"],
        2: ["eng-orchestrator", "architect", "challenger", "platform-engineer", "sre-devops", "test-runner", "security-reviewer", "verifier", "spec-guardian"],
        3: ["eng-orchestrator", "architect", "challenger", "platform-engineer", "sre-devops", "test-runner", "security-reviewer", "verifier", "spec-guardian"],
    },
    "spec-only": {
        1: ["eng-orchestrator", "requirements-analyst"],
        2: ["eng-orchestrator", "requirements-analyst", "challenger", "architect", "challenger"],
        3: ["eng-orchestrator", "requirements-analyst", "challenger", "architect", "challenger"],
    },
    "greenfield-feature": {
        1: ["eng-orchestrator", "requirements-analyst", "backend-engineer", "test-runner", "verifier"],
        2: [
            "eng-orchestrator", "requirements-analyst", "challenger", "architect", "challenger",
            "backend-engineer", "qa-engineer", "test-runner", "code-reviewer", "verifier", "spec-guardian",
        ],
        3: [
            "eng-orchestrator", "requirements-analyst", "challenger", "architect", "challenger",
            "backend-engineer", "frontend-engineer", "qa-engineer", "test-runner",
            "code-reviewer", "security-reviewer", "ponytail-review", "verifier", "spec-guardian",
        ],
    },
    "new-application": {
        1: ["eng-orchestrator", "requirements-analyst", "architect"],
        2: ["eng-orchestrator", "requirements-analyst", "challenger", "architect", "challenger"],
        3: ["eng-orchestrator", "requirements-analyst", "challenger", "architect", "challenger"],
    },
    "advisory-only": {0: ["eng-orchestrator"], 1: ["eng-orchestrator"], 2: ["eng-orchestrator"], 3: ["eng-orchestrator"]},
    "docs-touch": {1: ["eng-orchestrator"], 2: ["eng-orchestrator"], 3: ["eng-orchestrator"]},
    "vendor-sync": {1: ["eng-orchestrator"], 2: ["eng-orchestrator"], 3: ["eng-orchestrator"]},
}

CEILING = {
    "hotfix": ["eng-orchestrator", "debugger", "backend-engineer", "test-runner", "security-reviewer", "code-reviewer", "verifier", "spec-guardian"],
    "bug-fix": ["eng-orchestrator", "debugger", "backend-engineer", "test-runner", "code-reviewer", "security-reviewer", "verifier", "spec-guardian"],
    "maintenance": ["eng-orchestrator", "architect", "challenger", "backend-engineer", "test-runner", "code-reviewer", "security-reviewer", "verifier", "spec-guardian"],
    "security-patch": ["eng-orchestrator", "security-reviewer", "backend-engineer", "test-runner", "security-reviewer", "verifier", "spec-guardian"],
    "infra-change": ["eng-orchestrator", "architect", "challenger", "platform-engineer", "sre-devops", "test-runner", "security-reviewer", "verifier", "spec-guardian"],
    "spec-only": ["eng-orchestrator", "requirements-analyst", "challenger", "architect", "challenger"],
    "greenfield-feature": [
        "eng-orchestrator", "requirements-analyst", "challenger", "architect", "challenger",
        "backend-engineer", "frontend-engineer", "qa-engineer", "test-runner",
        "code-reviewer", "security-reviewer", "ponytail-review", "verifier", "spec-guardian",
    ],
    "new-application": [
        "eng-orchestrator", "requirements-analyst", "challenger", "architect", "challenger",
        "fullstack-engineer", "qa-engineer", "test-runner",
        "code-reviewer", "security-reviewer", "ponytail-review", "verifier", "spec-guardian",
    ],
    "advisory-only": ["eng-orchestrator"],
    "docs-touch": ["eng-orchestrator"],
    "vendor-sync": ["eng-orchestrator"],
}

if override:
    agents = [a.strip() for a in override.split(",") if a.strip()]
elif mode == "ceiling":
    if recipe not in CEILING:
        print(f"Unknown recipe: {recipe}", file=sys.stderr)
        sys.exit(1)
    agents = CEILING[recipe]
elif mode == "minimal":
    if recipe not in MINIMAL:
        print(f"Unknown recipe: {recipe}", file=sys.stderr)
        sys.exit(1)
    by_tier = MINIMAL[recipe]
    # fall back to nearest defined tier
    if tier in by_tier:
        agents = by_tier[tier]
    elif tier <= 1 and 1 in by_tier:
        agents = by_tier[1]
    elif 2 in by_tier:
        agents = by_tier[2]
    else:
        agents = by_tier[max(by_tier)]
else:
    print(f"Unknown mode: {mode} (use minimal|ceiling)", file=sys.stderr)
    sys.exit(1)

ti = to = 0
by_agent = {}
for a in agents:
    inp, out = AGENTS.get(a, (10000, 3000))
    ti += inp
    to += out
    by_agent[a] = by_agent.get(a, 0) + 1

total = ti + to
print(f"# Token estimate (heuristic) — recipe={recipe} tier={tier} mode={mode}")
print(f"# SoT for agent selection: ENGINEERING-RECIPES.md matrix + HANDOFF agents_planned.")
print(f"# Prefer --agents for exact planned estimate. Confidence: medium (±30–50%).")
print()
print(f"estimated_input:  {ti:,}")
print(f"estimated_output: {to:,}")
print(f"estimated_total:  {total:,}")
print(f"subagent_passes:  {len(agents)}")
print(f"unique_agents:    {len(by_agent)}")
print(f"mode:             {mode}")
print()
print("by_agent:")
for a, n in sorted(by_agent.items()):
    inp, out = AGENTS.get(a, (10000, 3000))
    print(f"  {a}: {n}x  (~{inp*n:,} in / ~{out*n:,} out)")
print()
print("# Adjustments: context-mode −20–40% effective input; long parent chat +50–200%; Principle 8 checkpoints −30–50% on late gates")
print("# Tier changes which agents are required (minimal lists) — not a blind multiplier on ceiling.")
PY
