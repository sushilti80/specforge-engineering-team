#!/usr/bin/env bash
# Bootstrap spec-driven scaffold into a project (plugin template).
# Usage: bash scripts/bootstrap-project.sh [--platform all|cursor|codex|opencode|claude|copilot|forge] /path/to/project
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$SCRIPT_DIR/deprecation-banner.sh" ]]; then
  # shellcheck source=deprecation-banner.sh
  source "$SCRIPT_DIR/deprecation-banner.sh"
  specforge_deprecation_banner
fi
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_ROOT="$PLUGIN_ROOT/templates/spec-driven-app"
PLATFORM="all"
PROJECT_ROOT=""

usage() {
  echo "Usage: bash scripts/bootstrap-project.sh [--platform all|cursor|codex|opencode|claude|copilot|forge] /path/to/project" >&2
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

# ForgeCode project-local symlinks (.forge/agents overrides ~/forge/agents)
# ForgeCode is a local CLI (no cloud agent), so symlinks to the plugin repo are fine.
# Agents carry both `name:` (Cursor/Claude) and `id:` (ForgeCode required).
if platform_enabled forge || platform_enabled all; then
  link_dir_contents "$PLUGIN_ROOT/agents" "$PROJECT_ROOT/.forge/agents" ".forge/agents"
  # ForgeCode custom commands: :commandname (optional nicety, mirrors slash commands)
  link_dir_contents "$PLUGIN_ROOT/commands" "$PROJECT_ROOT/.forge/commands" ".forge/commands"
fi

# Cross-tool skill symlinks (.agents/skills)
if platform_enabled codex || platform_enabled opencode || platform_enabled forge || platform_enabled all; then
  link_dir_contents "$PLUGIN_ROOT/skills" "$PROJECT_ROOT/.agents/skills" ".agents/skills"
fi

# Copilot cloud-safe bootstrap: vendor agents/skills/hooks/scripts into .github/
# (Copilot Cloud Agent cannot read $HOME; everything must live in the repo.)
if platform_enabled copilot || platform_enabled all; then
  echo "  Copilot: vendoring cloud-safe .github/ layout"
  GITHUB_DIR="$PROJECT_ROOT/.github"
  mkdir -p "$GITHUB_DIR/agents" "$GITHUB_DIR/skills" "$GITHUB_DIR/hooks"

  # Agents → .github/agents/<name>.agent.md (Copilot convention; copies, not symlinks)
  for agent in "$PLUGIN_ROOT/agents/"*.md; do
    [[ -f "$agent" ]] || continue
    base="$(basename "$agent")"
    stem="${base%.md}"
    copilot_name="${stem}.agent.md"
    if [[ -e "$GITHUB_DIR/agents/$copilot_name" ]]; then
      echo "  skip (exists): .github/agents/$copilot_name"
    else
      cp "$agent" "$GITHUB_DIR/agents/$copilot_name"
      echo "  copied: .github/agents/$copilot_name"
    fi
  done

  # Skills → .github/skills/ (copies so cloud runner can read them)
  if [[ -d "$PLUGIN_ROOT/skills" ]]; then
    for skill_dir in "$PLUGIN_ROOT/skills/"*/; do
      [[ -d "$skill_dir" ]] || continue
      sname="$(basename "$skill_dir")"
      if [[ -e "$GITHUB_DIR/skills/$sname" ]]; then
        echo "  skip (exists): .github/skills/$sname"
      else
        cp -R "$skill_dir" "$GITHUB_DIR/skills/$sname"
        echo "  copied: .github/skills/$sname"
      fi
    done
  fi

  # Vendor bridge.py + core hook scripts → scripts/specforge-hooks/
  SPECFORGE_HOOKS_DIR="$PROJECT_ROOT/scripts/specforge-hooks"
  mkdir -p "$SPECFORGE_HOOKS_DIR/scripts"
  cp "$PLUGIN_ROOT/hooks/adapters/bridge.py" "$SPECFORGE_HOOKS_DIR/bridge.py"
  chmod +x "$SPECFORGE_HOOKS_DIR/bridge.py" 2>/dev/null || true
  for hs in "$PLUGIN_ROOT/hooks/scripts/"*; do
    [[ -f "$hs" ]] || continue
    cp "$hs" "$SPECFORGE_HOOKS_DIR/scripts/$(basename "$hs")"
    chmod +x "$SPECFORGE_HOOKS_DIR/scripts/$(basename "$hs")" 2>/dev/null || true
  done
  echo "  vendored: scripts/specforge-hooks/ (bridge.py + $(ls "$SPECFORGE_HOOKS_DIR/scripts" | wc -l | tr -d ' ') scripts)"

  # Generate .github/hooks/specforge.json with RELATIVE paths to vendored bridge
  GITHUB_HOOKS_FILE="$GITHUB_DIR/hooks/specforge.json"
  REL_BRIDGE="python3 scripts/specforge-hooks/bridge.py"
  python3 - "$PLUGIN_ROOT/hooks/copilot/specforge.json" "$GITHUB_HOOKS_FILE" "$REL_BRIDGE" <<'PY'
import json, sys
template_path, out_path, bridge_cmd = sys.argv[1:4]
with open(template_path) as f:
    tpl = json.load(f)
def fill(obj):
    if isinstance(obj, dict): return {k: fill(v) for k, v in obj.items()}
    if isinstance(obj, list): return [fill(v) for v in obj]
    if isinstance(obj, str): return obj.replace("__SPECFORGE_BRIDGE__", bridge_cmd)
    return obj
tpl["hooks"] = fill(tpl["hooks"])
tpl.setdefault("version", 1)
import os
os.makedirs(os.path.dirname(out_path), exist_ok=True)
with open(out_path, "w") as f:
    json.dump(tpl, f, indent=2)
    f.write("\n")
print(out_path)
PY
  echo "  generated: .github/hooks/specforge.json (relative paths)"

  # AGENTS.md hint for Copilot (project-level)
  if [[ ! -f "$PROJECT_ROOT/.github/copilot-instructions.md" ]] && [[ -f "$PLUGIN_ROOT/templates/platform/AGENTS.copilot.md" ]]; then
    cp "$PLUGIN_ROOT/templates/platform/AGENTS.copilot.md" "$PROJECT_ROOT/.github/copilot-instructions.md"
    echo "  copied: .github/copilot-instructions.md"
  fi
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

# Project-runtime helpers referenced by hooks/playbook as scripts/<name> in the app repo.
# Distill is nudged by session-stop; estimate/collect are used for release metrics.
for script in distill-learning-journal.sh estimate-pipeline-tokens.sh collect-release-metrics.sh; do
  if [[ -f "$PLUGIN_ROOT/scripts/$script" ]]; then
    if [[ -f "$PROJECT_ROOT/scripts/$script" ]]; then
      echo "  skip (exists): scripts/$script"
    else
      cp "$PLUGIN_ROOT/scripts/$script" "$PROJECT_ROOT/scripts/$script"
      chmod +x "$PROJECT_ROOT/scripts/$script" 2>/dev/null || true
      echo "  copied: scripts/$script"
    fi
  else
    echo "  skip (missing in harness): scripts/$script" >&2
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

Start: project AGENTS.md — need checklist → smallest recipe × tier → user APPROVED before code.
First product session often: Tier 1, Recipe new-application (ARCH-000 optional at Tier 1).
EOF
  echo "  created: .specs/README.md"
fi

echo ""
echo "Done."
echo "  Memory:  $PROJECT_ROOT/.agents/memory/_project/MEMORY.md"
echo "  Specs:   $PROJECT_ROOT/.specs/requirements/REQ-001-product-scope.md"
case "$PLATFORM" in
  cursor)
    echo "  Next:    Cursor /eng-orchestrator (see AGENTS.md)"
    ;;
  codex)
    echo "  Next:    Codex — paste need/tier block from AGENTS.md (eng-orchestrator)"
    ;;
  opencode)
    echo "  Next:    OpenCode @eng-orchestrator (see AGENTS.md); /spec-pipeline is cheat sheet only"
    ;;
  claude)
    echo "  Next:    Claude — invoke eng-orchestrator with need/tier (see AGENTS.md)"
    ;;
  copilot)
    echo "  Next:    Copilot — @eng-orchestrator with need/tier (see .github/copilot-instructions.md)"
    ;;
  forge)
    echo "  Next:    ForgeCode — :agent eng-orchestrator with need/tier (see AGENTS.md)"
    ;;
  *)
    echo "  Next:    see AGENTS.md — need checklist → smallest recipe × tier → user APPROVED"
    ;;
esac
echo "  Tip:     commit .agents/memory if using git"
echo ""
