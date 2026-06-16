#!/usr/bin/env bash
# Bootstrap spec-driven scaffold into a project (plugin template).
# Usage: bash scripts/bootstrap-project.sh /path/to/project
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_ROOT="$PLUGIN_ROOT/templates/spec-driven-app"
PROJECT_ROOT="${1:-.}"

if [[ ! -d "$TEMPLATE_ROOT" ]]; then
  echo "Template not found: $TEMPLATE_ROOT" >&2
  exit 1
fi

if [[ ! -d "$PROJECT_ROOT" ]]; then
  echo "Creating project directory: $PROJECT_ROOT"
  mkdir -p "$PROJECT_ROOT"
fi

PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
echo "Bootstrapping spec-driven setup into: $PROJECT_ROOT"

# .specs
if [[ -d "$PROJECT_ROOT/.specs" ]]; then
  echo "  skip (exists): .specs/"
else
  cp -R "$TEMPLATE_ROOT/.specs" "$PROJECT_ROOT/.specs"
  echo "  copied: .specs/"
fi

# .cursor from cursor-overlay (avoids dot-folder copy issues in some environments)
mkdir -p "$PROJECT_ROOT/.cursor"
OVERLAY="$TEMPLATE_ROOT/cursor-overlay"
if [[ -d "$OVERLAY/rules" ]]; then
  mkdir -p "$PROJECT_ROOT/.cursor/rules"
  for f in "$OVERLAY/rules/"*.mdc; do
    [[ -f "$f" ]] || continue
    base="$(basename "$f")"
    if [[ -f "$PROJECT_ROOT/.cursor/rules/$base" ]]; then
      echo "  skip (exists): .cursor/rules/$base"
    else
      cp "$f" "$PROJECT_ROOT/.cursor/rules/$base"
      echo "  copied: .cursor/rules/$base"
    fi
  done
fi

if [[ -d "$PROJECT_ROOT/.cursor/agent-memory" ]]; then
  echo "  skip (exists): .cursor/agent-memory/"
elif [[ -d "$OVERLAY/agent-memory" ]]; then
  cp -R "$OVERLAY/agent-memory" "$PROJECT_ROOT/.cursor/agent-memory"
  echo "  copied: .cursor/agent-memory/"
fi

# scripts
mkdir -p "$PROJECT_ROOT/scripts"
for script in bootstrap-agent-memory.sh bootstrap-project.sh; do
  if [[ -f "$TEMPLATE_ROOT/scripts/$script" ]]; then
    if [[ -f "$PROJECT_ROOT/scripts/$script" ]]; then
      echo "  skip (exists): scripts/$script"
    else
      cp "$TEMPLATE_ROOT/scripts/$script" "$PROJECT_ROOT/scripts/$script"
      chmod +x "$PROJECT_ROOT/scripts/$script" 2>/dev/null || true
      echo "  copied: scripts/$script"
    fi
  fi
done

if [[ -x "$PROJECT_ROOT/scripts/bootstrap-agent-memory.sh" ]]; then
  (cd "$PROJECT_ROOT" && bash scripts/bootstrap-agent-memory.sh)
fi

if [[ ! -f "$PROJECT_ROOT/.cursorignore" ]]; then
  cat > "$PROJECT_ROOT/.cursorignore" <<'EOF'
dist/
build/
node_modules/
*.lock
coverage/
.nyc_output/
__pycache__/
*.egg-info/
.terraform/
*.tfstate
*.tfstate.backup
EOF
  echo "  created: .cursorignore"
fi

if [[ ! -f "$PROJECT_ROOT/.specs/README.md" ]]; then
  cat > "$PROJECT_ROOT/.specs/README.md" <<'EOF'
# Specs (source of truth)

- Requirements: `requirements/REQ-NNN-*.md`
- Architecture: `architecture/ARCH-NNN-*.md`
- Decisions: `decisions/ADR-NNN-*.md`
- Contracts: `contracts/`
- Test plans: `test-plans/TP-NNN-*.md`
- Bugs: `maintenance/BUG-NNN-*.md`

Playbook: `~/.cursor/ENGINEERING-PLAYBOOK.md`  
Plugin: `specforge-engineering-team`

Start: `/spec-pipeline` → Tier 1, Recipe `new-application`
EOF
  echo "  created: .specs/README.md"
fi

echo ""
echo "Done. Enable plugin in Cursor, then:"
echo "  1. Edit .cursor/agent-memory/_project/MEMORY.md"
echo "  2. Edit .specs/requirements/REQ-001-product-scope.md"
echo "  3. Agent: /spec-pipeline"
echo ""
