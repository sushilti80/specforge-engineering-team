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
  local agent count=0
  for agent in "$plugin_root/agents/"*.md; do
    [[ -f "$agent" ]] || continue
    local name
    name="$(basename "$agent")"
    ln -sfn "$agent" "$target_dir/$name"
    echo "  agent: $name"
    count=$((count + 1))
  done
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
