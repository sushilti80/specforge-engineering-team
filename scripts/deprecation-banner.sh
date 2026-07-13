#!/usr/bin/env bash
# Deprecation banner for legacy install/bootstrap scripts (AC-10).
# Source at top of install-*.sh and bootstrap-project.sh.
# Release workflow prepends this at tag time; dev checkout sources it directly.
specforge_deprecation_banner() {
  echo "⚠️  specforge: this script is deprecated." >&2
  echo "    Use \`specforge init <dir>\` / \`specforge link\` / \`specforge self-update\` instead." >&2
  echo "    This script will delegate to specforge when available." >&2
}

specforge_try_delegate() {
  local cmd="$1"
  shift
  if command -v specforge >/dev/null 2>&1; then
    specforge_deprecation_banner
    exec specforge "$cmd" "$@"
  fi
  if [[ -x "${HOME}/.local/bin/specforge" ]]; then
    specforge_deprecation_banner
    exec "${HOME}/.local/bin/specforge" "$cmd" "$@"
  fi
  local script_dir root
  script_dir="$(cd "$(dirname "${BASH_SOURCE[1]:-$0}")" && pwd)"
  if [[ "$(basename "$script_dir")" == "lib" ]]; then
    root="$(cd "$script_dir/../.." && pwd)"
  else
    root="$(cd "$script_dir/.." && pwd)"
  fi
  if [[ -x "$root/scripts/specforge.sh" ]]; then
    specforge_deprecation_banner
    exec bash "$root/scripts/specforge.sh" "$cmd" "$@"
  fi
  echo "  (specforge not on PATH — running legacy behavior)" >&2
  return 1
}
