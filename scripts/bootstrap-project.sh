#!/usr/bin/env bash
# Bootstrap spec-driven scaffold into a project (plugin template).
# Usage: bash scripts/bootstrap-project.sh [--platform all|cursor|codex|opencode|claude] /path/to/project
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_ROOT="$PLUGIN_ROOT/templates/spec-driven-app"
PLATFORM="all"
PROJECT_ROOT=""

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
    -h|--help)
      usage
      ;;
    *)
      PROJECT_ROOT="$1"
      shift
      ;;
  esac
done

[[ -n "$PROJECT_ROOT" ]] || PROJECT_ROOT="."

if [[ ! -d "$TEMPLATE_ROOT" ]]; then
  echo "Template not found: $TEMPLATE_ROOT" >&2
  exit 1
fi

if [[ ! -d "$PROJECT_ROOT" ]]; then
  echo "Creating project directory: $PROJECT_ROOT"
  mkdir -p "$PROJECT_ROOT"
fi

PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
echo "Bootstrapping spec-driven setup into: $PROJECT_ROOT (platform: $PLATFORM)"

platform_enabled() {
  local p="$1"
  [[ "$PLATFORM" == "all" || "$PLATFORM" == "$p" ]]
}

link_dir_contents() {
  local src="$1"
  local dest="$2"
  local label="$3"
  [[ -d "$src" ]] || return 0
  mkdir -p "$dest"
  local item
  for item in "$src"/*; do
    [[ -e "$item" ]] || continue
    local base
    base="$(basename "$item")"
    if [[ -e "$dest/$base" ]]; then
      echo "  skip (exists): $label/$base"
    else
      ln -sfn "$item" "$dest/$base"
      echo "  linked: $label/$base"
    fi
  done
}

# .specs
if [[ -d "$PROJECT_ROOT/.specs" ]]; then
  echo "  skip (exists): .specs/"
else
  cp -R "$TEMPLATE_ROOT/.specs" "$PROJECT_ROOT/.specs"
  echo "  copied: .specs/"
fi

# AGENTS.md (cross-tool project entry)
if [[ -f "$PROJECT_ROOT/AGENTS.md" ]]; then
  echo "  skip (exists): AGENTS.md"
elif [[ -f "$TEMPLATE_ROOT/AGENTS.md" ]]; then
  cp "$TEMPLATE_ROOT/AGENTS.md" "$PROJECT_ROOT/AGENTS.md"
  echo "  copied: AGENTS.md"
fi

# .agents/memory (canonical)
AGENTS_OVERLAY="$TEMPLATE_ROOT/agents-overlay"
if [[ -d "$PROJECT_ROOT/.agents/memory" ]]; then
  echo "  skip (exists): .agents/memory/"
elif [[ -d "$AGENTS_OVERLAY/memory" ]]; then
  mkdir -p "$PROJECT_ROOT/.agents"
  cp -R "$AGENTS_OVERLAY/memory" "$PROJECT_ROOT/.agents/memory"
  echo "  copied: .agents/memory/"
fi

# .cursor rules + memory symlink (Cursor compat)
if platform_enabled cursor || platform_enabled all; then
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

  if [[ -L "$PROJECT_ROOT/.cursor/agent-memory" || -d "$PROJECT_ROOT/.cursor/agent-memory" ]]; then
    if [[ -L "$PROJECT_ROOT/.cursor/agent-memory" ]]; then
      echo "  skip (exists): .cursor/agent-memory symlink"
    else
      echo "  skip (exists): .cursor/agent-memory/ (legacy dir — consider migrating to .agents/memory/)"
    fi
  elif [[ -d "$PROJECT_ROOT/.agents/memory" ]]; then
    ln -sfn "../.agents/memory" "$PROJECT_ROOT/.cursor/agent-memory"
    echo "  linked: .cursor/agent-memory -> .agents/memory"
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
fi

# OpenCode project-local symlinks
if platform_enabled opencode || platform_enabled all; then
  link_dir_contents "$PLUGIN_ROOT/agents" "$PROJECT_ROOT/.opencode/agents" ".opencode/agents"
  link_dir_contents "$PLUGIN_ROOT/commands" "$PROJECT_ROOT/.opencode/commands" ".opencode/commands"
fi

# Cross-tool skill symlinks (.agents/skills)
if platform_enabled codex || platform_enabled opencode || platform_enabled all; then
  link_dir_contents "$PLUGIN_ROOT/skills" "$PROJECT_ROOT/.agents/skills" ".agents/skills"
fi

# scripts
mkdir -p "$PROJECT_ROOT/scripts"
for script in bootstrap-agent-memory.sh; do
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
if [[ -f "$PLUGIN_ROOT/scripts/bootstrap-project.sh" ]]; then
  cp "$PLUGIN_ROOT/scripts/bootstrap-project.sh" "$PROJECT_ROOT/scripts/bootstrap-project.sh"
  chmod +x "$PROJECT_ROOT/scripts/bootstrap-project.sh" 2>/dev/null || true
  echo "  copied: scripts/bootstrap-project.sh (harness)"
fi

if [[ -x "$PROJECT_ROOT/scripts/bootstrap-agent-memory.sh" ]]; then
  (cd "$PROJECT_ROOT" && bash scripts/bootstrap-agent-memory.sh)
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

Playbook: `SPECFORGE_HOME/ENGINEERING-PLAYBOOK.md`  
Harness: `specforge-engineering-team`  
Roadmap (more platforms): `SPECFORGE_HOME/ROADMAP.md`

Start: see project `AGENTS.md` — Tier 1, Recipe `new-application`
EOF
  echo "  created: .specs/README.md"
fi

echo ""
echo "Done."
echo "  Memory:  $PROJECT_ROOT/.agents/memory/_project/MEMORY.md"
echo "  Specs:   $PROJECT_ROOT/.specs/requirements/REQ-001-product-scope.md"
echo "  Cursor:  /spec-pipeline  |  OpenCode: /spec-pipeline  |  Codex: see AGENTS.md"
echo ""
