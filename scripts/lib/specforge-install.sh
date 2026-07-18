#!/usr/bin/env bash
# Shared SpecForge install helpers — source from platform install scripts.
# Usage: source "$(dirname "$0")/lib/specforge-install.sh"
set -euo pipefail

SPECFORGE_DOCS=(
  ENGINEERING-PLAYBOOK.md
  ENGINEERING-RECIPES.md
  BOOTSTRAP-SPEC-DRIVEN-PROJECT.md
  SPEC-DRIVEN-EXECUTIVE-SUMMARY.md
  MULTI-TOOL.md
  ROADMAP.md
  ENGINEERING-METRICS.md
)

specforge_resolve_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[1]:-$0}")" && pwd)"
  if [[ "$(basename "$script_dir")" == "lib" ]]; then
    cd "$script_dir/../.." && pwd
  else
    cd "$script_dir/.." && pwd
  fi
}

link_agents() {
  local target_dir="$1"
  local plugin_root="${2:-$(specforge_resolve_root)}"
  mkdir -p "$target_dir"
  local agent rel dest count=0
  while IFS= read -r -d '' agent; do
    rel="${agent#"$plugin_root/agents/"}"
    dest="$target_dir/$rel"
    mkdir -p "$(dirname "$dest")"
    ln -sfn "$agent" "$dest"
    echo "  agent: $rel"
    count=$((count + 1))
  done < <(find "$plugin_root/agents" -name '*.md' -type f -print0 2>/dev/null)
  echo "  linked $count agents -> $target_dir"
}

link_skills() {
  local target_dir="$1"
  local plugin_root="${2:-$(specforge_resolve_root)}"
  mkdir -p "$target_dir"
  local skill_dir count=0
  for skill_dir in "$plugin_root/skills/"*/; do
    [[ -d "$skill_dir" ]] || continue
    local name
    name="$(basename "$skill_dir")"
    ln -sfn "$skill_dir" "$target_dir/$name"
    echo "  skill: $name"
    count=$((count + 1))
  done
  echo "  linked $count skills -> $target_dir"
}

link_docs() {
  local target_dir="$1"
  local plugin_root="${2:-$(specforge_resolve_root)}"
  mkdir -p "$target_dir"
  local doc count=0
  for doc in "${SPECFORGE_DOCS[@]}"; do
    if [[ -f "$plugin_root/docs/$doc" ]]; then
      ln -sfn "$plugin_root/docs/$doc" "$target_dir/$doc"
      echo "  doc: $doc"
      count=$((count + 1))
    fi
  done
  echo "  linked $count docs -> $target_dir"
}

link_commands() {
  local target_dir="$1"
  local plugin_root="${2:-$(specforge_resolve_root)}"
  mkdir -p "$target_dir"
  local cmd count=0
  for cmd in "$plugin_root/commands/"*.md; do
    [[ -f "$cmd" ]] || continue
    local name
    name="$(basename "$cmd")"
    ln -sfn "$cmd" "$target_dir/$name"
    echo "  command: $name"
    count=$((count + 1))
  done
  echo "  linked $count commands -> $target_dir"
}

install_agents_md() {
  local target_file="$1"
  local template_file="$2"
  mkdir -p "$(dirname "$target_file")"
  if [[ -f "$template_file" ]]; then
    cp "$template_file" "$target_file"
    echo "  installed: $target_file (from template)"
  else
    echo "  skip: template not found: $template_file" >&2
  fi
}

# Merge SpecForge hook groups into an existing hooks object (idempotent).
# Strips prior entries whose command mentions bridge.py or --specforge, then appends fresh ones.
_specforge_merge_hooks_py() {
  python3 - "$@" <<'PY'
import json
import os
import sys

settings_path, fragment_path, bridge_path, mode = sys.argv[1:5]
# mode: "settings"  → Claude settings.json with top-level "hooks" (group shape)
#       "hooksfile" → Codex hooks.json with top-level "hooks" (group shape)
#       "copilot"   → Copilot specforge.json with `version: 1` + flat hook lists

with open(fragment_path, encoding="utf-8") as f:
    fragment = json.load(f)

# Claude fragment is the hooks object itself; Codex/Copilot templates wrap under "hooks"
if mode in ("hooksfile", "copilot") and isinstance(fragment.get("hooks"), dict):
    new_hooks = fragment["hooks"]
elif isinstance(fragment, dict) and "SessionStart" in fragment:
    new_hooks = fragment
else:
    new_hooks = fragment.get("hooks") or fragment

bridge_cmd = f'python3 {bridge_path}'

def fill(obj):
    if isinstance(obj, dict):
        return {k: fill(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [fill(v) for v in obj]
    if isinstance(obj, str):
        return obj.replace("__SPECFORGE_BRIDGE__", bridge_cmd)
    return obj

new_hooks = fill(new_hooks)

def is_specforge_command(cmd: str) -> bool:
    if not isinstance(cmd, str):
        return False
    return ("hooks/adapters/bridge.py" in cmd) or ("--specforge" in cmd)

def is_specforge_hook_entry(h: dict) -> bool:
    """Detect SpecForge-owned hook entries across platforms."""
    if not isinstance(h, dict):
        return False
    # Claude/Codex use "command"; Copilot uses "bash".
    for key in ("command", "bash"):
        if is_specforge_command(h.get(key) or ""):
            return True
    return False

def strip_specforge(hooks_obj: dict) -> dict:
    cleaned = {}
    for event, entries in (hooks_obj or {}).items():
        if not isinstance(entries, list):
            cleaned[event] = entries
            continue
        kept = []
        for item in entries:
            if not isinstance(item, dict):
                kept.append(item)
                continue
            # Flat shape (Copilot): item IS a hook entry with bash/command + type.
            if "hooks" not in item and is_specforge_hook_entry(item):
                continue
            # Group shape (Claude/Codex): item has a "hooks" sub-list.
            hooks_list = item.get("hooks")
            if isinstance(hooks_list, list):
                kept_hooks = [h for h in hooks_list if not is_specforge_hook_entry(h)]
                if kept_hooks:
                    g = dict(item)
                    g["hooks"] = kept_hooks
                    kept.append(g)
                continue
            kept.append(item)
        if kept:
            cleaned[event] = kept
    return cleaned

if os.path.isfile(settings_path):
    try:
        with open(settings_path, encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError:
        data = {}
else:
    data = {}

if not isinstance(data, dict):
    data = {}

existing_hooks = data.get("hooks") if isinstance(data.get("hooks"), dict) else {}
merged = strip_specforge(existing_hooks)

for event, groups in new_hooks.items():
    merged.setdefault(event, [])
    if not isinstance(merged[event], list):
        merged[event] = []
    if isinstance(groups, list):
        merged[event].extend(groups)
    else:
        merged[event].append(groups)

data["hooks"] = merged
if mode == "copilot":
    data.setdefault("version", 1)
os.makedirs(os.path.dirname(settings_path) or ".", exist_ok=True)
tmp = settings_path + ".specforge.tmp"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
os.replace(tmp, settings_path)
print(settings_path)
PY
}

install_claude_hooks() {
  local claude_home="$1"
  local plugin_root="${2:-$(specforge_resolve_root)}"
  local settings_file="$claude_home/settings.json"
  local fragment="$plugin_root/hooks/claude/hooks.fragment.json"
  local bridge="$plugin_root/hooks/adapters/bridge.py"

  if [[ ! -f "$fragment" ]]; then
    echo "  skip hooks: missing $fragment" >&2
    return 0
  fi
  if [[ ! -f "$bridge" ]]; then
    echo "  skip hooks: missing $bridge" >&2
    return 0
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "  skip hooks: python3 required" >&2
    return 0
  fi

  mkdir -p "$claude_home"
  chmod +x "$bridge" 2>/dev/null || true
  chmod +x "$plugin_root/hooks/scripts/"* 2>/dev/null || true

  local out
  out="$(_specforge_merge_hooks_py "$settings_file" "$fragment" "$bridge" settings)"
  echo "  hooks: merged SpecForge → $out"
  echo "  events: SessionStart UserPromptSubmit SubagentStop PostToolUse Stop"
}

install_codex_hooks() {
  local codex_home="$1"
  local plugin_root="${2:-$(specforge_resolve_root)}"
  local hooks_file="$codex_home/hooks.json"
  local template="$plugin_root/hooks/codex/hooks.json"
  local bridge="$plugin_root/hooks/adapters/bridge.py"

  if [[ ! -f "$template" ]]; then
    echo "  skip hooks: missing $template" >&2
    return 0
  fi
  if [[ ! -f "$bridge" ]]; then
    echo "  skip hooks: missing $bridge" >&2
    return 0
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "  skip hooks: python3 required" >&2
    return 0
  fi

  mkdir -p "$codex_home"
  chmod +x "$bridge" 2>/dev/null || true
  chmod +x "$plugin_root/hooks/scripts/"* 2>/dev/null || true

  local out
  out="$(_specforge_merge_hooks_py "$hooks_file" "$template" "$bridge" hooksfile)"
  echo "  hooks: merged SpecForge → $out"
  echo "  events: SessionStart UserPromptSubmit SubagentStop PostToolUse Stop"
  echo "  trust:  open Codex CLI → /hooks → trust SpecForge entries"
}

install_copilot_hooks() {
  local copilot_home="$1"
  local plugin_root="${2:-$(specforge_resolve_root)}"
  local hooks_file="$copilot_home/hooks/specforge.json"
  local template="$plugin_root/hooks/copilot/specforge.json"
  local bridge="$plugin_root/hooks/adapters/bridge.py"

  if [[ ! -f "$template" ]]; then
    echo "  skip hooks: missing $template" >&2
    return 0
  fi
  if [[ ! -f "$bridge" ]]; then
    echo "  skip hooks: missing $bridge" >&2
    return 0
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "  skip hooks: python3 required" >&2
    return 0
  fi

  mkdir -p "$(dirname "$hooks_file")"
  chmod +x "$bridge" 2>/dev/null || true
  chmod +x "$plugin_root/hooks/scripts/"* 2>/dev/null || true

  local out
  out="$(_specforge_merge_hooks_py "$hooks_file" "$template" "$bridge" copilot)"
  echo "  hooks: merged SpecForge → $out"
  echo "  events: sessionStart userPromptSubmitted subagentStop postToolUse agentStop"
  echo "  trust:  Copilot CLI — verify hooks load (run 'copilot hooks list' or equivalent)"
}

# Copilot custom agents live as <name>.agent.md with YAML frontmatter.
link_copilot_agents() {
  local target_dir="$1"
  local plugin_root="${2:-$(specforge_resolve_root)}"
  mkdir -p "$target_dir"
  local agent count=0
  for agent in "$plugin_root/agents/"*.md; do
    [[ -f "$agent" ]] || continue
    local base
    base="$(basename "$agent")"
    # Drop existing extension, then add .agent.md (Copilot convention).
    local stem="${base%.md}"
    local copilot_name="${stem}.agent.md"
    ln -sfn "$agent" "$target_dir/$copilot_name"
    echo "  agent: $copilot_name"
    count=$((count + 1))
  done
  echo "  linked $count agents → $target_dir"
}
