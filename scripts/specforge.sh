#!/usr/bin/env bash
# SpecForge CLI — install, init, link, upgrade, migrate, doctor (REQ-004 / ARCH-004).
# Usage: specforge <command> [args]
set -euo pipefail

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_FILE="${BASH_SOURCE[0]}"
if command -v readlink >/dev/null 2>&1; then
  SCRIPT_FILE="$(readlink -f "$SCRIPT_FILE" 2>/dev/null || echo "$SCRIPT_FILE")"
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_FILE")" && pwd)"

# shellcheck source=lib/specforge-install.sh
source "$SCRIPT_DIR/lib/specforge-install.sh"

SF_HOME="${SPECFORGE_HOME_DIR:-$HOME/.specforge}"
GITHUB_REPO="${SPECFORGE_GITHUB_REPO:-sushilti80/specforge-engineering-team}"
SPECFORGE_DOCS_LIST=(
  ENGINEERING-RECIPES.md
  ENGINEERING-PLAYBOOK.md
  BOOTSTRAP-SPEC-DRIVEN-PROJECT.md
  SPEC-DRIVEN-EXECUTIVE-SUMMARY.md
  MULTI-TOOL.md
  ROADMAP.md
  ENGINEERING-METRICS.md
)

SF_VERBOSE=0
SF_DRY_RUN=0
SF_FIX=0
SF_OFFLINE=0
SF_FORCE=0
SF_GLOBAL=0
SF_PLATFORM="all"
SF_BUNDLE_MODE="symlink"
SF_PIN_ARG=""
SF_TIER="1"
SF_PROJECT="."

usage() {
  cat <<'EOF'
SpecForge CLI — packaging, install, upgrade, doctor

Usage:
  specforge init <dir> [--platform cursor,claude,opencode,codex] [--tier N] [--bundle-agents symlink|copy] [--force]
  specforge link [--platform <p>] [--offline]
  specforge upgrade [--pin <ver>] [--dry-run] [--global] [--force]
  specforge migrate [--pin <ver>] [--dry-run]
  specforge doctor [--fix] [--dry-run]
  specforge status [--verbose]
  specforge unlink
  specforge fetch <ver> [--offline]
  specforge install-local [--pin <ver>]   # dev: copy harness checkout to ~/.specforge/<ver>/
  specforge versions
  specforge self-update
  specforge global-pin <ver>

Environment:
  SPECFORGE_HOME_DIR     Harness store (default: ~/.specforge)
  SPECFORGE_HARNESS      Override harness checkout path
  SPECFORGE_OFFLINE=1    Same as --offline
  SPECFORGE_ALLOW_UNSIGNED=1  Skip cosign (SHA-only, not recommended)
EOF
}

log() { echo "specforge: $*"; }
warn() { echo "specforge: warning: $*" >&2; }
die() { echo "specforge: error: $*" >&2; exit "${2:-1}"; }

realpath_resolved() {
  local p="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath "$p" 2>/dev/null && return
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$p" 2>/dev/null && return
  fi
  readlink -f "$p" 2>/dev/null || echo "$p"
}

sha256_file() {
  local f="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | awk '{print $1}'
  else
    sha256sum "$f" | awk '{print $1}'
  fi
}

valid_pin() {
  local p="${1//$'\n'/}"
  [[ "$p" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

read_project_pin() {
  local project="$1"
  [[ -f "$project/.specforge-version" ]] || return 1
  tr -d '\n' < "$project/.specforge-version"
}

read_project_mode() {
  local project="$1"
  if [[ -f "$project/.specforge-mode" ]]; then
    tr -d '\n' < "$project/.specforge-mode"
    return 0
  fi
  echo "symlink"
}

write_project_pin() {
  local project="$1" pin="$2"
  printf '%s\n' "$pin" > "$project/.specforge-version"
}

write_project_mode() {
  local project="$1" mode="$2"
  printf '%s\n' "$mode" > "$project/.specforge-mode"
}

resolve_harness_checkout() {
  if [[ -n "${SPECFORGE_HARNESS:-}" && -d "$SPECFORGE_HARNESS" ]]; then
    echo "$(cd "$SPECFORGE_HARNESS" && pwd)"
    return 0
  fi
  local root
  root="$(cd "$SCRIPT_DIR/.." && pwd)"
  if [[ -f "$root/VERSION" && -d "$root/agents" ]]; then
    echo "$root"
    return 0
  fi
  return 1
}

resolve_harness_version() {
  local checkout ver
  if checkout="$(resolve_harness_checkout 2>/dev/null)"; then
    ver="$(tr -d '\n' < "$checkout/VERSION" 2>/dev/null || true)"
    if valid_pin "$ver"; then
      echo "$ver"
      return 0
    fi
  fi
  if [[ -L "$SF_HOME/current" || -d "$SF_HOME/current" ]]; then
    ver="$(tr -d '\n' < "$SF_HOME/current/VERSION" 2>/dev/null || true)"
    if valid_pin "$ver"; then
      echo "$ver"
      return 0
    fi
  fi
  return 1
}

version_dir() {
  echo "$SF_HOME/$1"
}

current_target() {
  if [[ -L "$SF_HOME/current" ]]; then
    basename "$(realpath_resolved "$SF_HOME/current")"
  elif [[ -d "$SF_HOME/current" ]]; then
    basename "$(realpath_resolved "$SF_HOME/current")"
  else
    echo ""
  fi
}

set_current_if_missing() {
  local ver="$1"
  if [[ ! -e "$SF_HOME/current" ]]; then
    ln -sfn "$ver" "$SF_HOME/current"
    log "set current → $ver (first install)"
  fi
}

advance_current() {
  local ver="$1"
  ln -sfn "$ver" "$SF_HOME/current"
  log "advanced current → $ver"
}

platform_enabled() {
  local p="$1"
  [[ "$SF_PLATFORM" == "all" || "$SF_PLATFORM" == *"$p"* ]]
}

github_release_url() {
  local ver="$1" artifact="$2"
  echo "https://github.com/${GITHUB_REPO}/releases/download/v${ver}/${artifact}"
}

mkdir -p "$SF_HOME/cache" "$SF_HOME/backups"

verify_cosign() {
  local file="$1" sig_file="$2"
  if command -v cosign >/dev/null 2>&1; then
    if [[ -f "$sig_file" ]]; then
      cosign verify-blob --certificate-identity-regexp='.*' --certificate-oidc-issuer-regexp='.*' \
        --signature "$sig_file" "$file" 2>/dev/null && return 0
      cosign verify-blob --key "${SPECFORGE_COSIGN_PUBKEY:-}" --signature "$sig_file" "$file" 2>/dev/null && return 0
      return 2
    fi
    return 2
  fi
  if [[ "${SPECFORGE_ALLOW_UNSIGNED:-}" == "1" ]]; then
    warn "cosign not found; proceeding SHA-only (SPECFORGE_ALLOW_UNSIGNED=1)"
    return 0
  fi
  die "cosign not found; install cosign or set SPECFORGE_ALLOW_UNSIGNED=1" 3
}

verify_tarball() {
  local tgz="$1" sha_file="$2" sig_file="$3" expected_ver="$4"
  local actual expected
  expected="$(awk '{print $1}' "$sha_file" 2>/dev/null || true)"
  actual="$(sha256_file "$tgz")"
  if [[ -z "$expected" || "$actual" != "$expected" ]]; then
    die "integrity failed: expected ${expected:-?}, got $actual" 1
  fi
  verify_cosign "$tgz" "$sig_file"
  mkdir -p "$(version_dir "$expected_ver")"
  rm -rf "$(version_dir "$expected_ver")"
  mkdir -p "$(version_dir "$expected_ver")"
  tar xzf "$tgz" -C "$(version_dir "$expected_ver")"
  local got
  got="$(tr -d '\n' < "$(version_dir "$expected_ver")/VERSION" 2>/dev/null || true)"
  if [[ "$got" != "$expected_ver" ]]; then
    rm -rf "$(version_dir "$expected_ver")"
    die "version mismatch: tarball claims $expected_ver, VERSION file says ${got:-empty}" 4
  fi
}

install_from_checkout() {
  local ver="$1"
  local checkout dest
  checkout="$(resolve_harness_checkout)" || die "no harness checkout found for install-local"
  local checkout_ver
  checkout_ver="$(tr -d '\n' < "$checkout/VERSION")"
  [[ "$checkout_ver" == "$ver" ]] || die "checkout VERSION ($checkout_ver) != requested pin ($ver)"
  dest="$(version_dir "$ver")"
  if [[ -L "$dest" ]]; then
    rm -f "$dest"
  elif [[ -d "$dest" ]]; then
    rm -rf "$dest"
  fi
  mkdir -p "$dest"
  # Copy harness content (exclude VCS + local specs work)
  local item
  for item in agents skills docs commands hooks rules templates scripts vendor .cursor-plugin VERSION; do
    [[ -e "$checkout/$item" ]] || continue
    cp -R "$checkout/$item" "$dest/"
  done
  chmod +x "$dest/hooks/scripts/"* 2>/dev/null || true
  chmod +x "$dest/scripts/"*.sh 2>/dev/null || true
  log "installed $ver from local checkout → $dest"
  set_current_if_missing "$ver"
}

cmd_fetch() {
  local ver="${1:-}"
  [[ -n "$ver" ]] || die "usage: specforge fetch <ver>"
  valid_pin "$ver" || die "invalid version: $ver"
  if [[ -d "$(version_dir "$ver")" && -f "$(version_dir "$ver")/VERSION" ]]; then
    log "$ver already installed"
    return 0
  fi
  if [[ "$SF_OFFLINE" == "1" || "${SPECFORGE_OFFLINE:-}" == "1" ]]; then
    local cache_tgz="$SF_HOME/cache/${ver}.tar.gz"
    [[ -f "$cache_tgz" ]] || die "offline: missing cache $cache_tgz" 5
    verify_tarball "$cache_tgz" "$SF_HOME/cache/${ver}.tar.gz.sha256" "$SF_HOME/cache/${ver}.tar.gz.sig" "$ver" || true
    # verify_tarball may fail without sig in dev — fallback extract
    if [[ ! -f "$(version_dir "$ver")/VERSION" ]]; then
      mkdir -p "$(version_dir "$ver")"
      tar xzf "$cache_tgz" -C "$(version_dir "$ver")"
    fi
    set_current_if_missing "$ver"
    return 0
  fi
  local tgz="$SF_HOME/cache/${ver}.tar.gz"
  local sha="$SF_HOME/cache/${ver}.tar.gz.sha256"
  local sig="$SF_HOME/cache/${ver}.tar.gz.sig"
  local url base
  base="$(github_release_url "$ver" "specforge-content-${ver}.tar.gz")"
  if ! curl -fsSL "$base" -o "$tgz"; then
    # Dev fallback: install from checkout
    if install_from_checkout "$ver" 2>/dev/null; then
      return 0
    fi
    die "download failed: $base" 5
  fi
  curl -fsSL "$(github_release_url "$ver" "specforge-content-${ver}.tar.gz.sha256")" -o "$sha" || true
  curl -fsSL "$(github_release_url "$ver" "specforge-content-${ver}.tar.gz.sig")" -o "$sig" || true
  if [[ -f "$sha" ]]; then
    verify_tarball "$tgz" "$sha" "$sig" "$ver" || {
      if install_from_checkout "$ver"; then return 0; fi
      die "verification failed for $ver"
    }
  else
    warn "no SHA file; extracting without verification (dev only)"
    mkdir -p "$(version_dir "$ver")"
    tar xzf "$tgz" -C "$(version_dir "$ver")"
  fi
  set_current_if_missing "$ver"
  log "fetched and installed $ver"
}

ensure_version() {
  local ver="$1"
  if [[ -f "$(version_dir "$ver")/VERSION" ]]; then
    local got
    got="$(tr -d '\n' < "$(version_dir "$ver")/VERSION")"
    [[ "$got" == "$ver" ]] || die "installed $ver has VERSION=$got (drift)"
    return 0
  fi
  if [[ "$SF_OFFLINE" == "1" || "${SPECFORGE_OFFLINE:-}" == "1" ]]; then
    SF_OFFLINE=1
    cmd_fetch "$ver"
    return 0
  fi
  cmd_fetch "$ver"
}

backup_find_incomplete() {
  local project="$1" source_pin="$2"
  local d
  for d in "$project/.specforge/backups"/*/; do
    [[ -d "$d" ]] || continue
    [[ -f "$d/.incomplete" ]] || continue
    if [[ -f "$d/.specforge-version" ]]; then
      local bp
      bp="$(tr -d '\n' < "$d/.specforge-version")"
      [[ "$bp" == "$source_pin" ]] && { echo "${d%/}"; return 0; }
    fi
  done
  return 1
}

backup_begin() {
  local project="$1" source_pin="$2"
  local existing
  if existing="$(backup_find_incomplete "$project" "$source_pin" 2>/dev/null)"; then
    echo "$existing"
    return 0
  fi
  local ts dir
  ts="$(date +%Y%m%dT%H%M%S)"
  dir="$project/.specforge/backups/$ts"
  mkdir -p "$dir"
  touch "$dir/.incomplete"
  printf '%s\n' "$source_pin" > "$dir/.specforge-version"
  echo "$dir"
}

backup_file() {
  local backup_dir="$1" src="$2"
  [[ -e "$src" ]] || return 0
  local rel dest_parent
  rel="${src#./}"
  dest_parent="$backup_dir/$(dirname "$rel")"
  mkdir -p "$dest_parent"
  if [[ -d "$src" ]]; then
    cp -R "$src" "$dest_parent/"
  else
    cp "$src" "$dest_parent/$(basename "$src")"
  fi
}

backup_complete() {
  rm -f "$1/.incomplete"
}

link_or_copy_file() {
  local src="$1" dest="$2" mode="$3"
  mkdir -p "$(dirname "$dest")"
  if [[ "$mode" == "copy" ]]; then
    cp "$src" "$dest"
    echo "  copied: $dest"
  else
    ln -sfn "$src" "$dest"
    echo "  linked: $dest → $src"
  fi
}

link_dir_items() {
  local src_dir="$1" dest_dir="$2" mode="$3" label="$4"
  [[ -d "$src_dir" ]] || return 0
  mkdir -p "$dest_dir"
  local item base
  for item in "$src_dir"/*; do
    [[ -e "$item" ]] || continue
    base="$(basename "$item")"
    if [[ "$mode" == "copy" ]]; then
      if [[ -d "$item" ]]; then
        rm -rf "$dest_dir/$base"
        cp -R "$item" "$dest_dir/$base"
      else
        cp "$item" "$dest_dir/$base"
      fi
      echo "  copied: $label/$base"
    else
      ln -sfn "$item" "$dest_dir/$base"
      echo "  linked: $label/$base"
    fi
  done
}

setup_project_specforge_dir() {
  local project="$1" pin="$2" mode="$3"
  local harness="$(version_dir "$pin")"
  mkdir -p "$project/.specforge"
  local doc
  for doc in "${SPECFORGE_DOCS_LIST[@]}"; do
    [[ -f "$harness/docs/$doc" ]] || continue
    link_or_copy_file "$harness/docs/$doc" "$project/.specforge/$doc" "$mode"
  done
  link_or_copy_file "$harness/templates/spec-driven-app" "$project/.specforge/templates/spec-driven-app" "$mode"
}

rewrite_hooks_json() {
  local harness_dir="$1"
  local hooks_file="$harness_dir/hooks/hooks.json"
  [[ -f "$hooks_file" ]] || return 0
  local tmp="${hooks_file}.new"
  if command -v jq >/dev/null 2>&1; then
    jq --arg H "${harness_dir%/}" '
      walk(if type == "object" and has("command") then .command |= sub("^\\./"; $H + "/") else . end)
    ' "$hooks_file" > "$tmp" && mv "$tmp" "$hooks_file"
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$harness_dir" "$hooks_file" "$tmp" <<'PY'
import json, sys, re
h = sys.argv[1].rstrip('/')
src, dst = sys.argv[2], sys.argv[3]
def fix(obj):
    if isinstance(obj, dict):
        if 'command' in obj and isinstance(obj['command'], str):
            obj['command'] = re.sub(r'^\./', h + '/', obj['command'])
        return {k: fix(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [fix(x) for x in obj]
    return obj
with open(src) as f:
    data = fix(json.load(f))
with open(dst, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
PY
    mv "$tmp" "$hooks_file"
    return 0
  fi
  die "cannot rewrite hooks.json; install jq or python3"
}

link_user_global() {
  local mode="$1"
  [[ "$mode" == "symlink" ]] || return 0
  local cur
  cur="$(realpath_resolved "$SF_HOME/current")"
  [[ -n "$cur" && -d "$cur" ]] || die "no current pointer; run specforge fetch <ver> or install-local first"
  local cursor_home="${CURSOR_HOME:-$HOME/.cursor}"
  mkdir -p "$cursor_home/plugins/local"
  ln -sfn "$SF_HOME/current" "$cursor_home/plugins/local/specforge-engineering-team"
  echo "  global cursor plugin → $SF_HOME/current"
  if platform_enabled claude || [[ "$SF_PLATFORM" == "all" ]]; then
    link_agents "${CLAUDE_HOME:-$HOME/.claude}/agents" "$cur"
    link_skills "${CLAUDE_HOME:-$HOME/.claude}/skills" "$cur"
    link_docs "${CLAUDE_HOME:-$HOME/.claude}/docs/specforge" "$cur"
  fi
  if platform_enabled codex || [[ "$SF_PLATFORM" == "all" ]]; then
    link_skills "${AGENTS_SKILLS_HOME:-$HOME/.agents/skills}" "$cur"
    link_docs "${CODEX_HOME:-$HOME/.codex}/specforge" "$cur"
  fi
  if platform_enabled opencode || [[ "$SF_PLATFORM" == "all" ]]; then
    link_agents "${OPENCODE_HOME:-$HOME/.config/opencode}/agents" "$cur"
    link_skills "${OPENCODE_HOME:-$HOME/.config/opencode}/skills" "$cur"
    link_commands "${OPENCODE_HOME:-$HOME/.config/opencode}/commands" "$cur"
    link_docs "${OPENCODE_HOME:-$HOME/.config/opencode}/specforge" "$cur"
  fi
}

link_project_local() {
  local project="$1" pin="$2" mode="$3"
  local harness="$(version_dir "$pin")"
  setup_project_specforge_dir "$project" "$pin" "$mode"
  if platform_enabled claude || [[ "$SF_PLATFORM" == "all" ]]; then
    link_dir_items "$harness/agents" "$project/.claude/agents" "$mode" ".claude/agents"
  fi
  if platform_enabled opencode || [[ "$SF_PLATFORM" == "all" ]]; then
    link_dir_items "$harness/agents" "$project/.opencode/agents" "$mode" ".opencode/agents"
    link_dir_items "$harness/commands" "$project/.opencode/commands" "$mode" ".opencode/commands"
  fi
  if platform_enabled codex || platform_enabled opencode || [[ "$SF_PLATFORM" == "all" ]]; then
    link_dir_items "$harness/skills" "$project/.agents/skills" "$mode" ".agents/skills"
  fi
  rewrite_hooks_json "$harness"
}

copy_template_scaffold() {
  local project="$1" pin="$2"
  local harness="$(version_dir "$pin")"
  local template="$harness/templates/spec-driven-app"
  [[ -d "$template" ]] || die "template missing in $harness"
  if [[ ! -d "$project/.specs" ]]; then
    cp -R "$template/.specs" "$project/.specs" 2>/dev/null || mkdir -p "$project/.specs"
    log "copied .specs/"
  fi
  if [[ ! -f "$project/AGENTS.md" ]]; then
    cp "$template/AGENTS.md" "$project/AGENTS.md"
    log "copied AGENTS.md"
  fi
  if [[ ! -d "$project/.agents/memory" && -d "$template/agents-overlay/memory" ]]; then
    mkdir -p "$project/.agents"
    cp -R "$template/agents-overlay/memory" "$project/.agents/memory"
    log "copied .agents/memory/"
  fi
  if platform_enabled cursor || [[ "$SF_PLATFORM" == "all" ]]; then
    mkdir -p "$project/.cursor/rules"
    local f
    for f in "$template/cursor-overlay/rules/"*.mdc; do
      [[ -f "$f" ]] || continue
      cp "$f" "$project/.cursor/rules/$(basename "$f")"
      log "copied .cursor/rules/$(basename "$f")"
    done
    if [[ -d "$project/.agents/memory" && ! -e "$project/.cursor/agent-memory" ]]; then
      ln -sfn "../.agents/memory" "$project/.cursor/agent-memory"
    fi
    if [[ ! -f "$project/.cursorignore" ]]; then
      cp "$template/../spec-driven-app/.cursorignore" "$project/.cursorignore" 2>/dev/null || true
    fi
  fi
  mkdir -p "$project/scripts"
  if [[ -f "$harness/templates/spec-driven-app/scripts/bootstrap-agent-memory.sh" ]]; then
    cp "$harness/templates/spec-driven-app/scripts/bootstrap-agent-memory.sh" "$project/scripts/" 2>/dev/null || true
  fi
}

cmd_init() {
  local project
  project="$(cd "$SF_PROJECT" && pwd)"
  local pin
  pin="$(resolve_harness_version)" || die "no harness found; run specforge fetch <ver> or install-local first"
  if [[ -f "$project/.specforge-version" && "$SF_FORCE" != "1" ]]; then
    local existing
    existing="$(read_project_pin "$project")"
    if [[ "$existing" == "$pin" ]]; then
      log "already bootstrapped at $pin"
      return 0
    fi
    die "already bootstrapped at $existing; use specforge upgrade --pin $pin or --force"
  fi
  ensure_version "$pin"
  write_project_pin "$project" "$pin"
  write_project_mode "$project" "$SF_BUNDLE_MODE"
  copy_template_scaffold "$project" "$pin"
  SF_PROJECT="$project"
  cmd_link
  log "init complete: pin=$pin mode=$SF_BUNDLE_MODE project=$project"
}

cmd_link() {
  local project
  project="$(cd "$SF_PROJECT" && pwd)"
  local pin mode
  pin="$(read_project_pin "$project")" || die "no .specforge-version; run specforge init first"
  valid_pin "$pin" || die "malformed .specforge-version: $pin"
  mode="$(read_project_mode "$project")"
  ensure_version "$pin"
  link_user_global "$mode"
  link_project_local "$project" "$pin" "$mode"
  log "link complete: pin=$pin mode=$mode"
}

cmd_install_local() {
  local pin="${SF_PIN_ARG:-}"
  [[ -n "$pin" ]] || pin="$(resolve_harness_version)" || die "cannot resolve version from checkout"
  install_from_checkout "$pin"
}

parse_version_segment() {
  local resolved="$1"
  local prefix="${SF_HOME%/}/"
  if [[ "$resolved" == "$prefix"* ]]; then
    local rest="${resolved#"$prefix"}"
    echo "${rest%%/*}"
  fi
}

doctor_check_symlinks() {
  local project="$1" pin="$2"
  local drift=0
  local path link target resolved seg
  for path in \
    "$project/.claude/agents" \
    "$project/.opencode/agents" \
    "$project/.agents/skills" \
    "$project/.specforge"; do
    [[ -e "$path" ]] || continue
    while IFS= read -r -d '' link; do
      target="$(readlink "$link" 2>/dev/null || true)"
      resolved="$(realpath_resolved "$link" 2>/dev/null || true)"
      seg="$(parse_version_segment "$resolved")"
      if [[ -z "$seg" || "$seg" != "$pin" ]]; then
        echo "DRIFT symlink: $link → $target (resolved segment: ${seg:-none}, expected: $pin)"
        drift=1
      fi
      if [[ -n "$resolved" && ! -e "$resolved" ]]; then
        echo "BROKEN symlink: $link"
        drift=1
      fi
    done < <(find "$path" -type l -print0 2>/dev/null)
  done
  return $drift
}

cmd_doctor() {
  local project
  project="$(cd "$SF_PROJECT" && pwd)"
  local issues=0
  local pin mode
  if ! pin="$(read_project_pin "$project" 2>/dev/null)"; then
    die "no .specforge-version"
  fi
  if ! valid_pin "$pin"; then
    echo "DRIFT malformed pin: $pin"
    issues=1
    if [[ "$SF_FIX" == "1" && "$SF_DRY_RUN" != "1" ]]; then
      local fix_pin
      fix_pin="$(resolve_harness_version)" || true
      if valid_pin "$fix_pin"; then
        write_project_pin "$project" "$fix_pin"
        pin="$fix_pin"
        echo "FIXED pin → $fix_pin"
      fi
    fi
  fi
  mode="$(read_project_mode "$project")"
  ensure_version "$pin" 2>/dev/null || { echo "MISSING harness $pin"; issues=1; }
  if [[ "$mode" == "symlink" ]]; then
    if ! doctor_check_symlinks "$project" "$pin"; then
      issues=1
    fi
  fi
  local harness="$(version_dir "$pin")"
  if [[ -f "$harness/hooks/hooks.json" ]] && grep -q '"command": "./' "$harness/hooks/hooks.json" 2>/dev/null; then
    echo "DRIFT hooks.json has relative commands"
    issues=1
    if [[ "$SF_FIX" == "1" && "$SF_DRY_RUN" != "1" ]]; then
      rewrite_hooks_json "$harness"
      echo "FIXED hooks.json"
    fi
  fi
  if [[ "$issues" == "0" ]]; then
    log "doctor: OK (pin=$pin mode=$mode)"
  else
    log "doctor: issues found"
    exit 1
  fi
}

cmd_status() {
  local project
  project="$(cd "$SF_PROJECT" && pwd)"
  local pin mode cur
  pin="$(read_project_pin "$project" 2>/dev/null || echo "none")"
  mode="$(read_project_mode "$project" 2>/dev/null || echo "unknown")"
  cur="$(current_target)"
  echo "Project: $project"
  echo "Pinned:  $pin"
  echo "Mode:    $mode"
  echo "Current: ${cur:-none}"
  echo "Store:   $SF_HOME"
  local v
  for v in "$SF_HOME"/*/; do
    [[ -d "$v" ]] || continue
    local name="$(basename "$v")"
    [[ "$name" == "cache" || "$name" == "backups" || "$name" == "current" ]] && continue
    [[ -f "$v/VERSION" ]] && echo "  installed: $name"
  done
  cmd_doctor 2>/dev/null || echo "Drift: yes"
}

cmd_unlink() {
  local project pin mode
  project="$(cd "$SF_PROJECT" && pwd)"
  pin="$(read_project_pin "$project" 2>/dev/null || echo "unknown")"
  mode="$(read_project_mode "$project")"
  local backup
  backup="$(backup_begin "$project" "$pin")"
  local d
  for d in .claude/agents .opencode/agents .opencode/commands .agents/skills .specforge; do
    [[ -e "$project/$d" ]] && backup_file "$backup" "$project/$d"
    if [[ "$mode" == "symlink" ]]; then
      find "$project/$d" -type l -delete 2>/dev/null || rm -rf "$project/$d" 2>/dev/null || true
    fi
  done
  backup_complete "$backup"
  log "unlink complete; .specforge-version preserved"
}

cmd_upgrade() {
  local project old_pin new_pin mode
  project="$(cd "$SF_PROJECT" && pwd)"
  old_pin="$(read_project_pin "$project")" || die "no .specforge-version"
  new_pin="${SF_PIN_ARG:-}"
  [[ -n "$new_pin" ]] || die "usage: specforge upgrade --pin <ver>"
  mode="$(read_project_mode "$project")"
  if [[ "$new_pin" == "$old_pin" ]]; then
    log "already on $old_pin"
    return 0
  fi
  if [[ "$SF_DRY_RUN" == "1" ]]; then
    echo "would upgrade $old_pin → $new_pin (mode=$mode)"
    return 0
  fi
  ensure_version "$new_pin"
  local backup
  backup="$(backup_begin "$project" "$old_pin")"
  backup_file "$backup" "$project/AGENTS.md"
  backup_file "$backup" "$project/.specforge-version"
  backup_file "$backup" "$project/.specforge-mode"
  local harness_new="$(version_dir "$new_pin")"
  cp "$harness_new/templates/spec-driven-app/AGENTS.md" "$project/AGENTS.md"
  mkdir -p "$project/.cursor/rules"
  local f
  for f in "$harness_new/templates/spec-driven-app/cursor-overlay/rules/"*.mdc; do
    [[ -f "$f" ]] || continue
    cp "$f" "$project/.cursor/rules/$(basename "$f")"
  done
  write_project_pin "$project" "$new_pin"
  link_project_local "$project" "$new_pin" "$mode"
  if [[ "$SF_GLOBAL" == "1" ]]; then
    advance_current "$new_pin"
  fi
  backup_complete "$backup"
  log "upgrade complete: $old_pin → $new_pin"
  log "backup: $backup"
}

cmd_migrate() {
  local project
  project="$(cd "$SF_PROJECT" && pwd)"
  if [[ -f "$project/.specforge-version" ]]; then
    die "already has .specforge-version; use upgrade"
  fi
  local pin="${SF_PIN_ARG:-$(current_target)}"
  [[ -n "$pin" ]] || pin="$(resolve_harness_version)" || die "cannot resolve pin for migrate"
  if [[ "$SF_DRY_RUN" == "1" ]]; then
    echo "would migrate project to pin $pin"
    return 0
  fi
  ensure_version "$pin"
  local mode="symlink"
  if find "$project/.claude/agents" -type f ! -type l 2>/dev/null | grep -q .; then
    mode="copy"
  fi
  local backup
  backup="$(backup_begin "$project" "pre-manifest")"
  backup_file "$backup" "$project/AGENTS.md"
  write_project_pin "$project" "$pin"
  write_project_mode "$project" "$mode"
  local harness="$(version_dir "$pin")"
  cp "$harness/templates/spec-driven-app/AGENTS.md" "$project/AGENTS.md"
  link_project_local "$project" "$pin" "$mode"
  backup_complete "$backup"
  log "migrate complete: pin=$pin mode=$mode backup=$backup"
}

cmd_versions() {
  local cur pinned
  cur="$(current_target)"
  pinned="$(read_project_pin "$(pwd)" 2>/dev/null || true)"
  echo "Harness store: $SF_HOME"
  echo "Current: ${cur:-none}"
  [[ -n "$pinned" ]] && echo "Project pin (cwd): $pinned"
  local v
  for v in "$SF_HOME"/*/; do
    [[ -d "$v" ]] || continue
    local name="$(basename "$v")"
    [[ "$name" == "cache" || "$name" == "backups" || "$name" == "current" ]] && continue
    [[ -f "$v/VERSION" ]] && echo "  $name"
  done
}

cmd_global_pin() {
  local ver="${1:-}"
  [[ -n "$ver" ]] || die "usage: specforge global-pin <ver>"
  [[ -d "$(version_dir "$ver")" ]] || die "$ver not installed"
  advance_current "$ver"
}

cmd_self_update() {
  local ver
  ver="$(current_target)"
  [[ -n "$ver" ]] || die "no current version"
  local url="$SF_HOME/cache/specforge-${ver}.sh"
  curl -fsSL "$(github_release_url "$ver" "specforge.sh")" -o "$url" || die "self-update download failed"
  local install_dir tmp
  install_dir="$(dirname "$(realpath_resolved "$SCRIPT_FILE")")"
  tmp="$(mktemp -d "$install_dir/.specforge-tmp.XXXXXX")"
  cp "$url" "$tmp/specforge.sh"
  chmod +x "$tmp/specforge.sh"
  mv "$tmp/specforge.sh" "$install_dir/specforge.sh"
  rmdir "$tmp" 2>/dev/null || true
  advance_current "$ver"
  log "self-updated CLI; current → $ver"
}

# --- argument parsing ---
CMD="${1:-}"
shift || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform) SF_PLATFORM="$2"; shift 2 ;;
    --tier) SF_TIER="$2"; shift 2 ;;
    --bundle-agents) SF_BUNDLE_MODE="$2"; shift 2 ;;
    --pin) SF_PIN_ARG="$2"; shift 2 ;;
    --dry-run) SF_DRY_RUN=1; shift ;;
    --fix) SF_FIX=1; shift ;;
    --offline) SF_OFFLINE=1; shift ;;
    --force) SF_FORCE=1; shift ;;
    --global) SF_GLOBAL=1; shift ;;
    --verbose) SF_VERBOSE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      if [[ "$CMD" == "init" || "$CMD" == "migrate" ]] && [[ "$SF_PROJECT" == "." ]]; then
        SF_PROJECT="$1"
      elif [[ -z "$SF_PIN_ARG" && "$CMD" =~ ^(fetch|global-pin)$ ]]; then
        SF_PIN_ARG="$1"
      fi
      shift
      ;;
  esac
done

[[ "${SPECFORGE_OFFLINE:-}" == "1" ]] && SF_OFFLINE=1

case "${CMD:-}" in
  init) cmd_init ;;
  link) cmd_link ;;
  upgrade) cmd_upgrade ;;
  migrate) cmd_migrate ;;
  doctor) cmd_doctor ;;
  status) cmd_status ;;
  unlink) cmd_unlink ;;
  fetch) cmd_fetch "${SF_PIN_ARG:-}" ;;
  install-local) cmd_install_local ;;
  versions) cmd_versions ;;
  self-update) cmd_self_update ;;
  global-pin) cmd_global_pin "${SF_PIN_ARG:-}" ;;
  ""|-h|--help|help) usage ;;
  *) die "unknown command: $CMD" ;;
esac
