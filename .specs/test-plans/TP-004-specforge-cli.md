# TP-004: SpecForge CLI — test plan

**Status**: Draft
**Date**: 2026-07-12 · **Links**: REQ-004 (Approved) · ARCH-004 (Approved) · ADR-006..010

## 1. Scope

Verify `scripts/specforge.sh` satisfies REQ-004 AC-1 through AC-22 on macOS (primary) and Linux (CI).

## 2. Environment

| Fixture | Purpose |
|---------|---------|
| `tmp/sf-test-empty/` | Fresh project dir (AC-1, AC-16) |
| `tmp/sf-test-migrate/` | Pre-manifest project with copied agents (AC-4) |
| `tmp/sf-test-copy/` | Copy-mode project (AC-7, AC-14) |
| `~/.specforge/` | Harness store (isolated via `SPECFORGE_HOME_DIR` in tests) |

**Test harness:** `scripts/test-specforge.sh` sets `SPECFORGE_HOME_DIR` to a temp dir and uses `install-local` from harness checkout when GitHub fetch unavailable.

## 3. Test matrix

| ID | AC | Command | Expected |
|----|-----|---------|----------|
| T-01 | AC-1 | `specforge init . --platform cursor,claude --tier 1` | `.specforge-version`, `AGENTS.md`, `.agents/memory/_project/MEMORY.md`, `.specs/README.md`, `.specforge/` symlinks to concrete pin |
| T-02 | AC-2 | `specforge doctor` | All project symlinks resolve to `~/.specforge/<pin>/`; exit 0 |
| T-03 | AC-3 | `specforge link` then inspect hooks | No `"command": "./` in harness `hooks.json` |
| T-04 | AC-4 | `specforge migrate` on pre-manifest fixture | `.specforge-version` written; agents symlinked; `.specs/` + `.agents/memory/` unchanged |
| T-05 | AC-5 | `specforge upgrade --pin X` | Symlinks + pin updated; `AGENTS.md` overwritten with backup |
| T-06 | AC-6 | `specforge doctor --fix` with one broken symlink | Repaired; report lists changes |
| T-07 | AC-7 | `specforge init --bundle-agents copy` | Files copied; `doctor` reports copies not broken symlinks |
| T-08 | AC-8 | `specforge link` without local version | Fetch + SHA verify (+ sig if cosign); extract to `~/.specforge/<pin>/` |
| T-09 | AC-9 | `specforge status` | ≤50 lines default; non-zero on drift |
| T-10 | AC-10 | `bash scripts/bootstrap-project.sh` | Deprecation warning; still works |
| T-11 | AC-11 | `specforge migrate --dry-run` | Prints plan; no filesystem changes |
| T-12 | AC-12 | `specforge upgrade` | Backup dir created; path printed |
| T-13 | AC-13 | Interrupt + re-run `upgrade` | Converges; reuses `.incomplete` backup |
| T-14 | AC-14 | `upgrade` in copy mode | Changed files re-copied by hash |
| T-15 | AC-15 | `specforge link --offline` | Uses cache; fails if cache missing |
| T-16 | AC-16 | `specforge init` on bootstrapped project | No-op or refuse on pin mismatch |
| T-17 | AC-17 | `specforge self-update` | Atomic rename; verifies SHA+sig |
| T-18 | AC-18 | `specforge fetch <ver>` | Extracts; does not move `current` if exists |
| T-19 | AC-19 | `specforge versions` | Lists installed; marks `current` |
| T-20 | AC-20 | `specforge unlink` | Project symlinks removed; `.specs/` preserved |
| T-21 | AC-21 | Two projects, divergent pins | `doctor` warns |
| T-22 | AC-22 | Malformed `.specforge-version` | `doctor` reports drift |

## 4. Manual smoke (post-implementation)

1. `bash scripts/specforge.sh install-local` from harness checkout → populates `~/.specforge/2.0.1/`
2. `specforge init /tmp/sf-smoke --platform cursor,claude`
3. `specforge doctor` → OK
4. `specforge status` → pinned 2.0.1, no drift

## 5. CI (deferred)

GitHub Actions job on `ubuntu-latest` + `macos-latest`: run `scripts/test-specforge.sh` with isolated `SPECFORGE_HOME_DIR`.
