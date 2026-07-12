#!/usr/bin/env bash
# Install SpecForge Engineering Team for all supported platforms.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$ROOT/scripts/deprecation-banner.sh" ]]; then
  # shellcheck source=deprecation-banner.sh
  source "$ROOT/scripts/deprecation-banner.sh"
  specforge_deprecation_banner
  specforge_try_delegate install-local || true
fi
bash "$ROOT/scripts/sync-ponytail.sh"
bash "$ROOT/scripts/install.sh" "$ROOT"
bash "$ROOT/scripts/install-claude.sh"
bash "$ROOT/scripts/install-codex.sh"
bash "$ROOT/scripts/install-opencode.sh"
echo "SpecForge installed for Cursor, Claude, Codex, and OpenCode."
