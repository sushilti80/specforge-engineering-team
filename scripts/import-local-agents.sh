#!/usr/bin/env bash
# Import standalone agent .md files from a local tool dir into repo agents/.
# Skips symlinks (already linked to harness). Preserves engineering/ subdirs.
#
# Usage:
#   bash scripts/import-local-agents.sh              # dry-run
#   bash scripts/import-local-agents.sh --apply      # copy into repo
#   bash scripts/import-local-agents.sh --apply --source ~/.claude/agents
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="${HOME}/.claude/agents"
APPLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --source) SOURCE="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,8p' "$0"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

[[ -d "$SOURCE" ]] || { echo "import-local-agents: source not found: $SOURCE" >&2; exit 1; }

imported=0
skipped=0

import_file() {
  local src="$1" dest="$2"
  local dest_dir
  dest_dir="$(dirname "$dest")"
  mkdir -p "$dest_dir"

  if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
    echo "  skip (identical): ${dest#"$ROOT"/}"
    skipped=$((skipped + 1))
    return 0
  fi

  if [[ -f "$dest" ]]; then
    echo "  update: ${dest#"$ROOT"/} (differs from source)"
  else
    echo "  add:    ${dest#"$ROOT"/}"
  fi

  if [[ "$APPLY" == "1" ]]; then
    cp "$src" "$dest"
  fi
  imported=$((imported + 1))
}

echo "import-local-agents: source=$SOURCE"
echo "import-local-agents: dest=$ROOT/agents/"
[[ "$APPLY" == "0" ]] && echo "import-local-agents: DRY RUN (pass --apply to write)"
echo ""

# Top-level standalone files
for src in "$SOURCE"/*.md; do
  [[ -f "$src" ]] || continue
  [[ ! -L "$src" ]] || { skipped=$((skipped + 1)); continue; }
  base="$(basename "$src")"
  import_file "$src" "$ROOT/agents/$base"
done

# engineering/ and other subdirs (one level deep)
for subdir in "$SOURCE"/*/; do
  [[ -d "$subdir" ]] || continue
  subname="$(basename "$subdir")"
  for src in "$subdir"/*.md; do
    [[ -f "$src" ]] || continue
    [[ ! -L "$src" ]] || { skipped=$((skipped + 1)); continue; }
    base="$(basename "$src")"
    import_file "$src" "$ROOT/agents/$subname/$base"
  done
done

echo ""
if [[ "$APPLY" == "0" ]]; then
  echo "Would import/update $imported file(s); skipped $skipped symlink(s)."
  echo "Run: bash scripts/import-local-agents.sh --apply"
else
  echo "Imported/updated $imported file(s); skipped $skipped symlink(s)."
  echo "Next: bash scripts/sync-dev-harness.sh && bash scripts/audit-agents.sh"
fi
