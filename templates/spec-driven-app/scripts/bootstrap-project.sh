#!/usr/bin/env bash
# Bootstrap spec-driven scaffold into a project (standalone template copy).
# Prefer harness script when installed: bash scripts/bootstrap-project.sh /path/to/project
# Usage: bash scripts/bootstrap-project.sh [--platform all|cursor|codex|opencode|claude] /path/to/project
set -euo pipefail

TEMPLATE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HARNESS_ROOT="$(cd "$TEMPLATE_ROOT/../.." && pwd)"
PLATFORM="all"
PROJECT_ROOT=""

if [[ -x "$HARNESS_ROOT/scripts/bootstrap-project.sh" && "$HARNESS_ROOT/scripts/bootstrap-project.sh" != "$0" ]]; then
  exec bash "$HARNESS_ROOT/scripts/bootstrap-project.sh" "$@"
fi

usage() {
  echo "Usage: bash scripts/bootstrap-project.sh [--platform all|cursor|codex|opencode|claude] /path/to/project" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform)
      [[ $# -ge 2 ]] || usage
      PLATFORM="$2"
      shift 2
      ;;
    -h|--help) usage ;;
    *) PROJECT_ROOT="$1"; shift ;;
  esac
done

[[ -n "$PROJECT_ROOT" ]] || PROJECT_ROOT="."
[[ -d "$PROJECT_ROOT" ]] || mkdir -p "$PROJECT_ROOT"
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"

echo "Bootstrapping spec-driven setup into: $PROJECT_ROOT (platform: $PLATFORM, template-only mode)"

# Minimal standalone bootstrap when harness script unavailable
if [[ ! -d "$PROJECT_ROOT/.specs" ]]; then
  cp -R "$TEMPLATE_ROOT/.specs" "$PROJECT_ROOT/.specs"
  echo "  copied: .specs/"
fi
if [[ ! -f "$PROJECT_ROOT/AGENTS.md" && -f "$TEMPLATE_ROOT/AGENTS.md" ]]; then
  cp "$TEMPLATE_ROOT/AGENTS.md" "$PROJECT_ROOT/AGENTS.md"
  echo "  copied: AGENTS.md"
fi
if [[ ! -d "$PROJECT_ROOT/.agents/memory" && -d "$TEMPLATE_ROOT/agents-overlay/memory" ]]; then
  mkdir -p "$PROJECT_ROOT/.agents"
  cp -R "$TEMPLATE_ROOT/agents-overlay/memory" "$PROJECT_ROOT/.agents/memory"
  echo "  copied: .agents/memory/"
fi
if [[ -d "$PROJECT_ROOT/.agents/memory" && ! -e "$PROJECT_ROOT/.cursor/agent-memory" ]]; then
  mkdir -p "$PROJECT_ROOT/.cursor"
  ln -sfn "../.agents/memory" "$PROJECT_ROOT/.cursor/agent-memory"
  echo "  linked: .cursor/agent-memory -> .agents/memory"
fi

mkdir -p "$PROJECT_ROOT/scripts"
for script in bootstrap-agent-memory.sh bootstrap-project.sh; do
  [[ -f "$TEMPLATE_ROOT/scripts/$script" && ! -f "$PROJECT_ROOT/scripts/$script" ]] && \
    cp "$TEMPLATE_ROOT/scripts/$script" "$PROJECT_ROOT/scripts/$script" && chmod +x "$PROJECT_ROOT/scripts/$script"
done

[[ -x "$PROJECT_ROOT/scripts/bootstrap-agent-memory.sh" ]] && (cd "$PROJECT_ROOT" && bash scripts/bootstrap-agent-memory.sh)

echo "Done. See AGENTS.md and SPECFORGE_HOME/BOOTSTRAP-SPEC-DRIVEN-PROJECT.md"
