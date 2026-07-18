#!/usr/bin/env bash
# Dev workflow: copy repo harness → ~/.specforge/<VERSION>/ and refresh symlinks.
#
# Edit agents in this repo, then run this script so Cursor/Claude/OpenCode
# pick up changes without manual copying.
#
# Usage:
#   bash scripts/sync-dev-harness.sh [--link-all]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINK_ALL=0
[[ "${1:-}" == "--link-all" ]] && LINK_ALL=1

export SPECFORGE_HARNESS="$ROOT"
SF="$ROOT/scripts/specforge.sh"

[[ -x "$SF" ]] || chmod +x "$SF"

VER="$(tr -d '\n' < "$ROOT/VERSION")"
echo "sync-dev-harness: repo=$ROOT"
echo "sync-dev-harness: version=$VER"
echo ""

bash "$SF" install-local --pin "$VER"
bash "$SF" global-pin "$VER"

if [[ "$LINK_ALL" == "1" ]]; then
  echo ""
  echo "Re-linking all platforms from ~/.specforge/current ..."
  bash "$ROOT/scripts/install.sh" "$ROOT" 2>/dev/null || true
  bash "$ROOT/scripts/install-claude.sh" 2>/dev/null || true
  bash "$ROOT/scripts/install-forge.sh" 2>/dev/null || true
  bash "$ROOT/scripts/install-opencode.sh" 2>/dev/null || true
fi

echo ""
echo "sync-dev-harness: done"
echo "  Cursor plugin → ~/.specforge/current (contents from repo)"
echo "  Re-link Claude/Forge: bash scripts/sync-dev-harness.sh --link-all"
echo "  Audit: bash scripts/audit-agents.sh --verbose"
