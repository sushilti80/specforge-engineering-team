#!/usr/bin/env bash
# Audit agent files across repo, ~/.specforge, and tool home dirs.
# Detects drift, stale copies, and orphans not tracked in git.
#
# Usage:
#   bash scripts/audit-agents.sh [--verbose] [--fix]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SF_HOME="${SPECFORGE_HOME_DIR:-$HOME/.specforge}"
CURSOR_HOME="${CURSOR_HOME:-$HOME/.cursor}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
VERBOSE=0
FIX=0
ISSUES=0

for arg in "$@"; do
  case "$arg" in
    --verbose|-v) VERBOSE=1 ;;
    --fix) FIX=1 ;;
  esac
done

log() { echo "audit-agents: $*"; }
issue() { echo "  ⚠ $*"; ISSUES=$((ISSUES + 1)); }
ok() { echo "  ✓ $*"; }

rel_agent_path() {
  local file="$1" base="$2"
  echo "${file#"$base"/}"
}

compare_trees() {
  local label="$1" a="$2" b="$3"
  local diffs
  diffs="$(diff -rq "$a" "$b" 2>/dev/null | grep -v 'Only in' || true)"
  if [[ -n "$diffs" ]]; then
    issue "$label differs"
    if [[ "$VERBOSE" == "1" ]]; then
      echo "$diffs" | sed 's/^/    /'
    else
      echo "$diffs" | wc -l | xargs -I{} echo "    {} file(s) differ (use --verbose)"
    fi
  else
    ok "$label matches"
  fi
}

list_only_in() {
  local label="$1" only_dir="$2" other_dir="$3"
  local missing
  missing="$(diff -rq "$only_dir" "$other_dir" 2>/dev/null | grep "^Only in $only_dir" || true)"
  if [[ -n "$missing" ]]; then
    issue "$label has files not in repo"
    echo "$missing" | sed 's/^/    /'
  fi
}

audit_standalone_dir() {
  local label="$1" dir="$2"
  [[ -d "$dir" ]] || return 0
  local f base repo_path
  local standalone=0
  while IFS= read -r -d '' f; do
    standalone=$((standalone + 1))
    base="$(basename "$f")"
    repo_path="$ROOT/agents/$base"
    if [[ -f "$repo_path" ]]; then
      if ! cmp -s "$f" "$repo_path" 2>/dev/null; then
        issue "$label/$base is a stale COPY (differs from repo; not a symlink)"
        if [[ "$FIX" == "1" ]]; then
          local backup="$CURSOR_HOME/agents.stale-$(date +%Y%m%d)"
          mkdir -p "$backup"
          mv "$f" "$backup/$base"
          echo "    fixed: moved to $backup/$base"
        fi
      else
        issue "$label/$base is a redundant COPY (same as repo; should be symlink or removed)"
        if [[ "$FIX" == "1" ]]; then
          local backup="$CURSOR_HOME/agents.stale-$(date +%Y%m%d)"
          mkdir -p "$backup"
          mv "$f" "$backup/$base"
          echo "    fixed: moved to $backup/$base"
        fi
      fi
    else
      issue "$label/$base is an ORPHAN (not in repo agents/)"
    fi
  done < <(find "$dir" -maxdepth 1 -type f -name '*.md' -print0 2>/dev/null)
  if [[ "$standalone" -eq 0 ]]; then
    ok "$label has no standalone top-level .md files"
  fi
}

audit_orphan_tree() {
  local label="$1" dir="$2" subpath="${3:-}"
  local search="$dir"
  [[ -n "$subpath" ]] && search="$dir/$subpath"
  [[ -d "$search" ]] || return 0
  local f rel repo_path
  while IFS= read -r -d '' f; do
    rel="$(rel_agent_path "$f" "$ROOT/agents")"
    if [[ "$f" == "$ROOT/agents/"* ]]; then
      continue
    fi
    rel="${f#"$search"/}"
    repo_path="$ROOT/agents/${subpath:+$subpath/}$rel"
    if [[ -L "$f" ]]; then
      local target resolved
      target="$(readlink "$f")"
      resolved="$(cd "$(dirname "$f")" && cd "$(dirname "$target")" 2>/dev/null && pwd)/$(basename "$target")" 2>/dev/null || true
      if [[ -n "$resolved" && "$resolved" != "$repo_path" && ! "$resolved" == "$ROOT/agents/"* ]]; then
        if [[ "$VERBOSE" == "1" ]]; then
          issue "$label symlink $rel → $target (not under repo agents/)"
        fi
      fi
      continue
    fi
    if [[ ! -f "$repo_path" ]]; then
      issue "$label ORPHAN: ${subpath:+$subpath/}$rel (not in repo)"
    elif ! cmp -s "$f" "$repo_path" 2>/dev/null; then
      issue "$label DRIFT: ${subpath:+$subpath/}$rel differs from repo"
    fi
  done < <(find "$search" -name '*.md' \( -type f -o -type l \) -print0 2>/dev/null)
}

echo ""
log "Harness repo: $ROOT"
log "Version:      $(tr -d '\n' < "$ROOT/VERSION" 2>/dev/null || echo unknown)"
echo ""

# --- Core SpecForge 20: repo vs installed harness ---
if [[ -d "$SF_HOME/current/agents" ]]; then
  echo "== Repo vs ~/.specforge/current/agents =="
  compare_trees "repo ↔ specforge/current" "$ROOT/agents" "$SF_HOME/current/agents"
  list_only_in "specforge/current" "$SF_HOME/current/agents" "$ROOT/agents"
  echo ""
else
  issue "~/.specforge/current/agents missing (run: bash scripts/sync-dev-harness.sh)"
  echo ""
fi

# --- Stale global Cursor copies (not used when plugin is enabled) ---
echo "== ~/.cursor/agents (global copies — often stale) =="
audit_standalone_dir "~/.cursor/agents" "$CURSOR_HOME/agents"
echo ""

# --- Claude: symlinks + orphans ---
echo "== ~/.claude/agents =="
audit_standalone_dir "~/.claude/agents (top-level)" "$CLAUDE_HOME/agents"
audit_orphan_tree "~/.claude/agents/engineering" "$CLAUDE_HOME/agents" "engineering"
echo ""

# --- Forge: should symlink to repo when developing ---
if [[ -d "$HOME/.forge/agents" ]]; then
  echo "== ~/.forge/agents =="
  local_count=0
  for f in "$HOME/.forge/agents"/*.md; do
    [[ -e "$f" ]] || continue
    if [[ -L "$f" ]]; then
      target="$(readlink "$f")"
      if [[ "$target" != "$ROOT/agents/"* ]]; then
        issue "~/.forge/agents/$(basename "$f") → $target (expected repo path)"
      fi
    else
      issue "~/.forge/agents/$(basename "$f") is a standalone file"
      local_count=$((local_count + 1))
    fi
  done
  if [[ "$local_count" -eq 0 ]]; then
    ok "~/.forge/agents symlinks point at repo (or dir empty)"
  fi
  echo ""
fi

# --- Cursor plugin pointer ---
echo "== Cursor plugin link =="
plugin_link="$CURSOR_HOME/plugins/local/specforge-engineering-team"
if [[ -L "$plugin_link" ]]; then
  target="$(readlink "$plugin_link")"
  if [[ "$target" == "$ROOT" ]]; then
    ok "Cursor plugin → repo (dev mode)"
  elif [[ "$target" == "$SF_HOME/current" || "$target" == "$SF_HOME/"* ]]; then
    ok "Cursor plugin → $target (release harness)"
    if [[ "$target" != "$SF_HOME/current" ]]; then
      issue "plugin target is not ~/.specforge/current"
    fi
  else
    issue "Cursor plugin → unexpected target: $target"
  fi
else
  issue "Cursor plugin link missing: $plugin_link"
fi
echo ""

# --- Git status for repo agents ---
echo "== Git (repo agents/) =="
if git -C "$ROOT" diff --quiet -- agents/ 2>/dev/null && \
   [[ -z "$(git -C "$ROOT" status --porcelain agents/ 2>/dev/null)" ]]; then
  ok "agents/ clean in git"
else
  issue "agents/ has uncommitted changes"
  git -C "$ROOT" status --short agents/ 2>/dev/null | sed 's/^/    /' || true
fi
echo ""

if [[ "$ISSUES" -eq 0 ]]; then
  log "OK — no drift detected"
else
  log "$ISSUES issue(s) found"
  echo ""
  echo "Fix workflow:"
  echo "  1. Edit agents in this repo: $ROOT/agents/"
  echo "  2. Import orphans:  bash scripts/import-local-agents.sh --apply"
  echo "  3. Push to harness: bash scripts/sync-dev-harness.sh"
  echo "  4. Re-audit:        bash scripts/audit-agents.sh --verbose"
  exit 1
fi
