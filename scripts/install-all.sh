#!/usr/bin/env bash
# Install SpecForge Engineering Team for both Cursor and Claude.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
bash "$ROOT/scripts/install.sh" "$ROOT"
bash "$ROOT/scripts/install-claude.sh"
echo "SpecForge installed for Cursor + Claude."
