#!/usr/bin/env bash
# Bootstrap spec-driven scaffold into a project.
# Usage: bash ~/.cursor/templates/spec-driven-app/scripts/bootstrap-project.sh /path/to/project
set -euo pipefail

TEMPLATE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="${1:-.}"

if [[ ! -d "$PROJECT_ROOT" ]]; then
  echo "Creating project directory: $PROJECT_ROOT"
  mkdir -p "$PROJECT_ROOT"
fi

PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
echo "Bootstrapping spec-driven setup into: $PROJECT_ROOT"

copy_if_missing() {
  local src="$1" dest="$2"
  if [[ -e "$dest" ]]; then
    echo "  skip (exists): $dest"
  else
    cp -R "$src" "$dest"
    echo "  copied: $dest"
  fi
}

# .specs
if [[ -d "$PROJECT_ROOT/.specs" ]]; then
  echo "  skip (exists): .specs/"
else
  cp -R "$TEMPLATE_ROOT/.specs" "$PROJECT_ROOT/.specs"
  echo "  copied: .specs/"
fi

# .cursor (rules + agent-memory)
mkdir -p "$PROJECT_ROOT/.cursor"
if [[ -d "$TEMPLATE_ROOT/.cursor/rules" ]]; then
  mkdir -p "$PROJECT_ROOT/.cursor/rules"
  for f in "$TEMPLATE_ROOT/.cursor/rules/"*.mdc; do
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
else
  cp -R "$TEMPLATE_ROOT/.cursor/agent-memory" "$PROJECT_ROOT/.cursor/agent-memory"
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
      chmod +x "$PROJECT_ROOT/scripts/$script"
      echo "  copied: scripts/$script"
    fi
  fi
done

# bootstrap all agent memory folders
if [[ -x "$PROJECT_ROOT/scripts/bootstrap-agent-memory.sh" ]]; then
  (cd "$PROJECT_ROOT" && bash scripts/bootstrap-agent-memory.sh)
fi

# .cursorignore
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
else
  echo "  skip (exists): .cursorignore"
fi

# optional: project README pointer
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
Bootstrap: `~/.cursor/BOOTSTRAP-SPEC-DRIVEN-PROJECT.md`

Start Agent chat: `/spec-pipeline` then Tier 1 `new-application` prompt.
EOF
  echo "  created: .specs/README.md"
fi

echo ""
echo "Done. Next steps:"
echo "  1. cd $PROJECT_ROOT"
echo "  2. Edit .cursor/agent-memory/_project/MEMORY.md"
echo "  3. Edit .specs/requirements/REQ-001-product-scope.md"
echo "  4. Open in Cursor → Agent: /spec-pipeline (see BOOTSTRAP-SPEC-DRIVEN-PROJECT.md)"
echo ""
echo "Optional: cp -R ~/.cursor/skills/spec-* .cursor/skills/"
