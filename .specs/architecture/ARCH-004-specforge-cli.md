# ARCH-004: SpecForge CLI — system design

**Status**: Draft R1 (READY_FOR_APPROVAL) — Challenger R0 BLOCKING resolved; see §12
**Date**: 2026-07-12 · **Owner**: architect (draft) / **User** (APPROVED) · **Links**: REQ-004 (Approved) · TP-004 (pending) · ADR-006..010 (pending)

## 1. Overview

A single bash CLI (`scripts/specforge.sh`) that manages SpecForge harness installation, project bootstrapping, version pinning, upgrade, and drift detection — without requiring Node, without manual symlink merging, and without `SPECFORGE_HOME` placeholder ambiguity.

```
┌─────────────────────────────────────────────────────────┐
│ User machine                                            │
│                                                         │
│  ~/.specforge/              ← canonical harness store   │
│    2.0.1/                   ← real dir (extracted)      │
│      agents/ skills/ docs/ hooks/ templates/ ...        │
│      VERSION               ← "2.0.1"                    │
│    2.1.0/                                              │
│    current → 2.0.1          ← user-global pointer       │
│      (set by fetch on first install; advanced by        │
│       self-update; NEVER moved by project-scoped cmds)  │
│    cache/                   ← verified tarballs         │
│      2.0.1.tar.gz + .sha256 + .sig                      │
│    backups/                 ← self backups (CLI only)   │
│    specforge.sh             ← the CLI (or ~/.local/bin) │
│                                                         │
│  ~/.cursor/plugins/local/                               │
│    specforge-engineering-team → ~/.specforge/current    │
│  ~/.claude/agents/*.md → ~/.specforge/current/agents/*  │
│  ~/.codex/specforge/*.md → ~/.specforge/current/docs/*  │
│  ~/.config/opencode/agents/* → ~/.specforge/current/*   │
│                                                         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Project repo (e.g. sales_architect)                     │
│                                                         │
│  .specforge-version        ← "2.0.1" (pin, one line)    │
│  .specforge-mode           ← "symlink"|"copy" (one line)│
│  .specforge/                                           │
│    ENGINEERING-RECIPES.md → ~/.specforge/2.0.1/docs/…   │ ← concrete, NOT current
│    ENGINEERING-PLAYBOOK.md → ~/.specforge/2.0.1/docs/…  │
│    templates/spec-driven-app → ~/.specforge/2.0.1/…     │
│    backups/<ts>/           ← migrate/upgrade backups    │
│      .incomplete            ← sentinel (removed on ok)  │
│  AGENTS.md                 ← copied (project owns)      │
│  .agents/memory/           ← project-owned, never touch │
│  .specs/                   ← project-owned, never touch │
│  .claude/agents/*.md → ~/.specforge/2.0.1/agents/*      │ ← concrete, NOT current
│  .opencode/agents/* → ~/.specforge/2.0.1/agents/*       │
│  .cursor/rules/*.mdc       ← copied (project owns)      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Key invariants:**
1. Project-local symlinks resolve to **concrete version dirs** (`~/.specforge/2.0.1/`), never `current`. User-global symlinks use `current`. A global upgrade never silently re-points pinned projects.
2. `current` is the user's "active global version." **Set** by `fetch` on first install (if missing). **Advanced** by `self-update`. **Never moved** by project-scoped commands (`init`, `link`, `upgrade`, `migrate`, `doctor`).
3. Bundle mode is persisted in `.specforge-mode` (one line: `symlink` or `copy`), written by `init`, read by `upgrade`/`doctor`/`link`.

## 2. Components

### 2.1 `scripts/specforge.sh` — the CLI

Single bash script, ~400-500 lines. Dependencies: coreutils (`ln`, `cp`, `rm`, `mkdir`, `readlink`, `stat`, `grep`, `sed`, `awk`, `tar`, `curl`); `shasum -a 256` (macOS) or `sha256sum` (Linux) via a `sha256()` helper; `cosign` (optional — see §6); `jq` (optional — see §4); `realpath` (coreutils, fallback to `readlink -f`).

**Structure:**
```
specforge.sh
  ├── detect_platform()      macOS/Linux/WSL/native-Win; picks sha256 + readlink impl
  ├── resolve_harness()      $SPECFORGE_HARNESS > adjacent VERSION > ~/.specforge/current/VERSION > error
  ├── sha256()               shasum -a 256 || sha256sum
  ├── realpath_resolved()    realpath || readlink -f
  ├── command dispatch
  │   ├── init)         bootstrap a project (calls link at end)
  │   ├── link)         wire tool dirs + project symlinks
  │   ├── upgrade)      change pinned version + refresh (symlink OR copy branch)
  │   ├── migrate)      adopt pre-manifest project
  │   ├── doctor)       verify + optionally fix
  │   ├── status)       print state summary
  │   ├── unlink)       remove project symlinks
  │   ├── fetch)        download+verify+extract version; set current if missing
  │   ├── versions)     list installed
  │   ├── self-update)  update CLI script + advance current
  │   └── global-pin)   explicitly move current to <ver>
  ├── helpers
  │   ├── verify_tarball()     SHA256 + cosign check (§6 failure contract)
  │   ├── backup_file()        copy to .specforge/backups/<ts>/ w/ .incomplete sentinel
  │   ├── rewrite_hooks()      jq-based, walks command fields only (§4)
  │   ├── detect_cloud_sync()  realpath + known-cloud-root check (§8)
  │   ├── scan_sibling_pins()  walk $HOME depth 4, collect .specforge-version (§3 doctor)
  │   └── read_mode()          cat .specforge-mode, default "symlink"
  └── self-install             install specforge.sh to ~/.local/bin
```

### 2.2 `VERSION` file

Single line: `2.0.1`. Generated from `plugin.json` `version` at release time. Lives at harness root. `resolve_harness()` reads it.

### 2.3 `.specforge-version` (project pin) & `.specforge-mode`

`.specforge-version`: one line, `2.0.1`, no `v` prefix, no ranges, optional trailing newline. Created by `init`, read by `link`/`doctor`/`upgrade`/`status`. Malformed (empty, multi-line, has `v`, non-numeric) = drift (AC-22); `doctor` reports and `--fix` rewrites from `resolve_harness()`.

`.specforge-mode`: one line, `symlink` or `copy`. Written by `init` from `--bundle-agents`. Read by `upgrade`/`doctor`/`link` to decide re-point vs. re-copy. Missing file + symlinks present → infer `symlink`. Missing file + copies present → infer `copy`. Ambiguous → `doctor` reports drift, `--fix` writes the inferred mode.

### 2.4 `~/.specforge/` layout

```
~/.specforge/
  VERSION                    ← "2.0.1" (copy, for quick check)
  2.0.1/                     ← real directory (extracted from tarball)
    agents/  skills/  docs/  commands/  hooks/  rules/
    templates/  scripts/  vendor/  .cursor-plugin/
    VERSION
  2.1.0/                     ← (when fetched)
  current → 2.0.1            ← user-global pointer (§1 invariant 2)
  cache/
    2.0.1.tar.gz             ← verified tarball (written by fetch/link)
    2.0.1.tar.gz.sha256
    2.0.1.tar.gz.sig
  backups/                   ← CLI self-backups (rare; mostly project-local)
  specforge.sh               ← the CLI (or ~/.local/bin/specforge)
```

### 2.5 Release artifacts (GitHub Release per tag)

```
v2.0.1/
  specforge-content-2.0.1.tar.gz    ← agents+skills+docs+hooks+templates+scripts+vendor+VERSION+.cursor-plugin
  specforge-content-2.0.1.tar.gz.sha256
  specforge-content-2.0.1.tar.gz.sig  ← cosign
  specforge.sh                       ← the CLI script
  specforge.sh.sha256
  specforge.sh.sig
```

## 3. Command designs

### `init <dir> [--platform cursor,claude] [--tier 1] [--bundle-agents symlink|copy]`

1. Resolve target dir (create if missing).
2. **Resolve pin via `resolve_harness()`**: `$SPECFORGE_HARNESS` env > adjacent `VERSION` (if `specforge.sh` is running from a harness checkout) > `~/.specforge/current/VERSION` > error ("no harness found; run `specforge fetch <ver>` first"). Pin = that VERSION.
3. If `.specforge-version` exists: refuse unless `--force`; recommend `specforge upgrade --pin <installed>` (AC-16). Print the existing pin.
4. Write `.specforge-version` = pin. Write `.specforge-mode` = `symlink` (default) or `copy` (`--bundle-agents copy`).
5. Create `.specforge/` symlinks to concrete version dir (`~/.specforge/<pin>/docs/...`, `~/.specforge/<pin>/templates/spec-driven-app`). In copy mode, copy these instead.
6. Copy `AGENTS.md` from `~/.specforge/<pin>/templates/spec-driven-app/AGENTS.md` (project owns it).
7. Copy `.cursor/rules/*.mdc` from `~/.specforge/<pin>/templates/spec-driven-app/cursor-overlay/rules/` (project owns them).
8. Copy `.agents/memory/` stubs from template if missing; create `.specs/` from template if missing (never overwrite existing `.specs/` or `.agents/memory/`).
9. **Delegate the rest to `link`** (covers all platforms uniformly — fixes nit 15): run `specforge link` at the end, which wires `.claude/agents/`, `.opencode/agents/`, `.agents/skills/`, user-global dirs, and rewrites hooks.
10. Print summary: pin, mode, platforms, paths.

### `link [--platform <p>] [--offline]`

1. Read `.specforge-version` → pin. Read `.specforge-mode` → mode.
2. If `~/.specforge/<pin>/` missing:
   - `--offline`: read from `~/.specforge/cache/<pin>.tar.gz` (AC-15). If missing → error "not in cache; run `specforge fetch <pin>` online first." Extract + verify (SHA from cache).
   - else: `fetch <pin>` (which downloads, verifies, extracts, and caches).
3. Verify `~/.specforge/<pin>/VERSION` == pin (else drift).
4. **User-global** (symlink mode only — copy mode skips user-global since each project owns copies): ensure `~/.cursor/plugins/local/specforge-engineering-team → ~/.specforge/current`. If `current` missing → error "no `current` pointer; run `specforge fetch <ver>` or `specforge self-update` first." **`link` NEVER moves `current`** (fixes blocking 2). Same ensure-not-repoint for `~/.claude/agents/*.md`, `~/.codex/specforge/`, `~/.config/opencode/agents/`.
5. **Project-local** (pin = concrete, NOT `current`):
   - symlink mode: `.claude/agents/*.md → ~/.specforge/<pin>/agents/*.md`, `.opencode/agents/* → ~/.specforge/<pin>/agents/*`, `.agents/skills/* → ~/.specforge/<pin>/skills/*`.
   - copy mode: `cp` each file from `~/.specforge/<pin>/agents/` to project dirs.
6. Rewrite `hooks.json` commands to absolute paths under `~/.specforge/<pin>/hooks/scripts/` (§4).
7. Print link matrix.

### `upgrade [--pin <ver>] [--dry-run] [--global]`

1. Read current `.specforge-version` → old pin. Read `.specforge-mode` → mode.
2. Resolve new pin: `--pin` arg, or `latest` tag from GitHub.
3. If `--dry-run`: print planned changes (AC-11), exit 0.
4. If new pin == old pin: print "already on <pin>", exit 0 (idempotent).
5. If new pin < old pin: warn "downgrade; agent prompts may have had fixes"; require `--force`.
6. Fetch new version if missing (AC-8 + §6 failure contract).
7. **Backup** (AC-12) with sentinel (fixes important 10): create `.specforge/backups/<ts>/` + `.incomplete`. Copy `AGENTS.md`, `.cursor/rules/*.mdc`, `.specforge-version`, `.specforge-mode`, and (in copy mode) the agent files that will be overwritten. Remove `.incomplete` only after step 12 succeeds.
8. **`--global` flag** (fixes blocking 1): if set, also move `current → <new-pin>` after success (this is the explicit way to advance the user-global pointer via upgrade). Without `--global`, `current` is untouched (project upgrade is project-scoped).
9. **Symlink mode**: re-point project-local symlinks to `~/.specforge/<new-pin>/`. Re-link `.specforge/` doc symlinks to new concrete dir.
   **Copy mode** (fixes blocking 4): re-copy changed files from `~/.specforge/<new-pin>/agents/` to project agent dirs. Compare by `sha256`; only copy if differs (idempotent). Same for `.specforge/` doc copies.
10. Overwrite `AGENTS.md` + `.cursor/rules/*.mdc` from new template (`~/.specforge/<new-pin>/templates/spec-driven-app/AGENTS.md` and `.../cursor-overlay/rules/`) — overwrite-with-backup (§5 of REQ). Print backup path prominently.
11. Update `.specforge-version` to new pin.
12. Rewrite hooks.
13. Remove `.incomplete` sentinel. Print backup path + summary.

### `migrate [--dry-run] [--pin <ver>]`

For pre-manifest projects (the `sales_architect` case):
1. Detect: no `.specforge-version`, but has `.claude/agents/*.md` (copies or stale symlinks) or `AGENTS.md` from old template.
2. If `--dry-run`: print planned deletions + symlink creations (AC-11).
3. Resolve pin: `--pin` arg, else `~/.specforge/current/VERSION`, else error.
4. **Backup** (AC-12) with `.incomplete` sentinel: copy every file that will be deleted/overwritten.
5. Detect mode: if existing agents are symlinks → `symlink`; if copies → `copy`. Write `.specforge-mode`.
6. Write `.specforge-version`.
7. Create `.specforge/` doc symlinks (or copies) to concrete version dir.
8. Replace copied agents with symlinks to `~/.specforge/<pin>/agents/*.md` (symlink mode) or re-copy from pin (copy mode).
9. **Always overwrite `AGENTS.md` from template, with backup** (fixes important 13 — drops the 90% heuristic for MVP; consistent with §5). Print backup path. The user re-merges customizations from `.specforge/backups/<ts>/AGENTS.md` if needed.
10. Preserve `.specs/` and `.agents/memory/` byte-for-byte (never touch).
11. Rewrite hooks. Remove `.incomplete`. Print backup path + what changed.

### `doctor [--fix] [--dry-run]`

1. Read `.specforge-version` → expected pin. Validate format (AC-22): one line, no `v`, numeric semver.
2. Read `.specforge-mode`. Validate; infer if missing (§2.3).
3. Walk every project-local symlink: `realpath_resolved` → parse the `~/.specforge/<seg>/` version segment → **string-compare `<seg>` == pin exactly** (fixes important 7 — no substring match). Mismatch = drift.
4. For copy-mode files: `sha256` → compare against `~/.specforge/<pin>/`. Mismatch = drift.
5. Check `hooks.json` commands are absolute (no leading `./`) (§4).
6. **Cloud-sync detection** (fixes important 8): `realpath_resolved ~/.specforge` → check under known cloud roots: `~/Library/Mobile Documents` (iCloud), `~/Library/CloudStorage/OneDrive*` (OneDrive), `~/Library/CloudStorage/GoogleDrive*`, `~/Dropbox`, `~/Google Drive`. If under one → **warn** (not fail, not drift): "`~/.specforge` is under <cloud>; symlinks may break or duplicate. Consider `~/.specforge` outside cloud sync or use `--bundle-agents copy`." (The current user's `$HOME` is on OneDrive — this warning will fire for them; it's informational.)
7. **Divergent-pin scan** (fixes important 12): walk `$HOME` to depth 4, skip `.git`, `node_modules`, `.venv`, `target`, `build`, `dist`, `.next`, `vendor`, collect `.specforge-version` values. Perf budget: <2s on a typical home with <10k dirs (skip the heavy dirs). Warn (not fail) on divergence (AC-21).
8. Report: OK / drift / broken / warning. Exit non-zero iff drift or broken (warnings don't fail).
9. If `--fix`: re-point drifted symlinks, re-copy drifted files, rewrite hooks, rewrite malformed `.specforge-version` from `resolve_harness()`. If `--dry-run`: print planned fixes only.

### `status`

Print ≤50 lines (AC-9): pinned version, mode, installed local versions, `current` target, per-platform link state (user-global + project-local), drift summary, cloud-sync warning if applicable. `--verbose` for full drift detail + sibling-pin table. Exit non-zero iff drift.

### `unlink`

Remove all project-local symlinks to `~/.specforge/` (or copied agent files in copy mode, after backup). Preserve `.specs/`, `.agents/memory/`, `.specforge-version`, `.specforge-mode` (so re-link is possible).

### `fetch <ver>`

1. Download `specforge-content-<ver>.tar.gz` + `.sha256` + `.sig` from GitHub Release to `~/.specforge/cache/`.
2. Verify (§6 failure contract): SHA256 check; cosign verify (if cosign available; else §6 fallback).
3. Extract to `~/.specforge/<ver>/`.
4. Verify `~/.specforge/<ver>/VERSION` == ver.
5. **Set `current` if missing** (fixes blocking 1): if `~/.specforge/current` does not exist, `ln -s <ver> current`. Do NOT move an existing `current`.
6. Keep the tarball in `cache/` (fixes blocking 5 — populates offline cache).

### `versions`

List `~/.specforge/*/` dirs (real dirs only, not `current`/`cache`/`backups`), mark `current` target, mark versions referenced by `.specforge-version` in CWD or parents.

### `self-update`

1. Read `~/.specforge/current/VERSION` → target ver (the global version the CLI should match).
2. Download `specforge.sh` + `.sha256` + `.sig` from GitHub Release for that ver.
3. Verify (§6).
4. **Atomic install** (fixes important 14): `mktemp -d` adjacent to the installed script location (`$(dirname "$(readlink -f "$0")")/.specforge-tmp.$$`), write new script there, `mv` (same-filesystem rename) over installed script.
5. **Advance `current`** (fixes blocking 1): `ln -sfn <ver> current` (the explicit global-advance path; `upgrade --global` is the other).
6. Print "self-updated to <ver>; current → <ver>".

### `global-pin <ver>` (new — fixes blocking 1, 2)

Explicitly move `current → ~/.specforge/<ver>`. Errors if `<ver>` not fetched. This is the manual override for the user-global pointer; complements the implicit advances in `fetch` (first install) and `self-update`.

### §3.x Deprecated installers (AC-10 — fixes blocking 3)

The existing `scripts/install-all.sh`, `install-claude.sh`, `install-codex.sh`, `install-opencode.sh`, `bootstrap-project.sh` are **kept working** with a deprecation banner. Mechanism:
- Each script gets a 5-line preamble prepended at release time (by the release workflow, §7) that prints to stderr:
  ```
  ⚠️  specforge: this script is deprecated.
      Use `specforge init <dir>` / `specforge link` / `specforge self-update` instead.
      This script will delegate to specforge and exit.
  ```
- Then `exec specforge <equivalent-command>` (delegation, not removal). If `specforge` not on `$PATH`, the script falls back to its old behavior with an extra warning.
- No CLI command deletes them.
- `doctor` reports if deprecated installers are present in the project's `scripts/` dir and suggests `specforge` migration (informational).

## 4. Hook rewriting (`rewrite_hooks`) — fixes important 9

`hooks/hooks.json` ships with `./hooks/scripts/...` commands (cwd-relative). Under `~/.specforge/<pin>/`, cwd is not guaranteed.

**Primary path (jq available):**
```bash
jq --arg H "$HARNESS_DIR" '
  # walk all "command" fields; replace leading "./" with $H/
  walk(. as $x | if type=="object" and has("command")
       then .command |= (sub("^\\./"; $H + "/"))
       else . end)
' hooks.json > hooks.json.new && mv hooks.json.new hooks.json
```
`jq`'s `walk` + `sub` touches **only** `command` fields and **only** leading `./`. Non-path `./` in other fields is untouched.

**Fallback (jq absent):** use `python3 -c` with `json` module (same semantics). If `python3` also absent → error: "cannot rewrite hooks.json safely; install jq or python3, or use `--bundle-agents copy` (hooks are then project-local and cwd-relative works)."

**Doctor check:** scan `hooks.json` for any `"command": "./` remaining → drift, `--fix` rewrites.

## 5. Backup & rollback (fixes important 10)

Every destructive command (`migrate`, `upgrade`, `unlink` in copy mode) writes to `.specforge/backups/<ISO8601>/` **with a `.incomplete` sentinel**:

```
.specforge/backups/2026-07-12T160500/
  .incomplete                ← present during mutation, removed on success
  AGENTS.md
  .cursor/rules/spec-driven.mdc
  .claude/agents/adr-recorder.md   ← old copied file, before symlink replacement
  .specforge-version               ← old pin
  .specforge-mode                  ← old mode
```

**Idempotency (AC-13):** on re-run after interruption:
1. If a `.specforge/backups/<ts>/.incomplete` exists for the same source pin → reuse that backup dir (do NOT create a new timestamp). Continue from where the run stopped.
2. Before each mutation, check current state: if a symlink already points to the correct version dir → skip. If a copy file already matches by hash → skip. Re-running converges to the same end state.
3. Only create a new backup timestamp when no incomplete sentinel exists for the source pin.

**Rollback** (manual for MVP): `cp -R .specforge/backups/<ts>/* .` + re-run `specforge link`. No automated `rollback` command in MVP (deferred — AC doesn't require it).

## 6. Security — tarball verification + failure contract (fixes important 11)

```
specforge fetch <ver>
  1. curl -L github.com/.../specforge-content-<ver>.tar.gz -o cache/<ver>.tar.gz
  2. curl ... .sha256
  3. sha256 check: shasum -a 256 cache/<ver>.tar.gz | diff - cache/<ver>.tar.gz.sha256
  4. cosign verify --key <embedded-pubkey> cache/<ver>.tar.gz   (if cosign present)
  5. tar xzf cache/<ver>.tar.gz -C ~/.specforge/<ver>/
  6. verify ~/.specforge/<ver>/VERSION == <ver>
```

**Failure contract (AC-8):**

| Failure | Exit | Print | Cleanup |
|---|---|---|---|
| SHA256 mismatch | 1 | "integrity failed: expected <exp>, got <act>" | `rm -rf ~/.specforge/<ver>/` (partial extract); keep cache tarball for forensics |
| cosign signature mismatch | 2 | "signature verification failed for <ver>" | `rm -rf ~/.specforge/<ver>/`; keep cache |
| cosign not installed (R3) | 3 | "cosign not found; install: https://...; or set `SPECFORGE_ALLOW_UNSIGNED=1` to proceed with SHA-only (not recommended)" | none — abort before extract |
| `SPECFORGE_ALLOW_UNSIGNED=1` set | 0 | warning "signature not verified (SHA-only)" | none — proceed |
| VERSION mismatch after extract | 4 | "version mismatch: tarball claims <ver>, VERSION file says <act>" | `rm -rf ~/.specforge/<ver>/` |
| download failure (curl) | 5 | "download failed: <url> <http_code>" | none |

**Public key** for cosign: published in repo README + embedded as a constant in `specforge.sh`. Key rotation = a CLI release (new embedded key). The user can audit the embedded key by reading the script before first `self-update`.

**Downgrade warning**: `upgrade --pin X` where X < current warns and requires `--force`.

## 7. Release flow (GitHub Actions, tag-triggered)

```yaml
# .github/workflows/release.yml
on:
  push:
    tags: ['v*']
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: bash scripts/sync-ponytail.sh          # bake Ponytail into tarball (ADR-009)
      - run: echo "$(jq -r .version .cursor-plugin/plugin.json)" > VERSION
      - run: |
          # prepend deprecation banner to legacy installers (§3.x, AC-10)
          for s in install-all.sh install-claude.sh install-codex.sh install-opencode.sh bootstrap-project.sh; do
            [ -f scripts/$s ] && cat scripts/deprecation-banner.sh scripts/$s > scripts/$s.new && mv scripts/$s.new scripts/$s
          done
      - run: tar czf specforge-content-${VERSION}.tar.gz agents/ skills/ docs/ commands/ hooks/ rules/ templates/ scripts/ vendor/ VERSION .cursor-plugin/
      - run: shasum -a 256 specforge-content-*.tar.gz > specforge-content-*.tar.gz.sha256
      - run: cosign sign-blob --key env://COSIGN_KEY specforge-content-*.tar.gz
      - run: cp scripts/specforge.sh specforge.sh && shasum -a 256 specforge.sh > specforge.sh.sha256
      - run: cosign sign-blob --key env://COSIGN_KEY specforge.sh
      - uses: softprops/action-gh-release@v2
        with:
          files: |
            specforge-content-*.tar.gz
            specforge-content-*.tar.gz.sha256
            specforge-content-*.tar.gz.sig
            specforge.sh
            specforge.sh.sha256
            specforge.sh.sig
```

**Single source of truth:** `plugin.json` `version` → `VERSION` file → embedded in tarball. CLI reads `VERSION`. No triple-tracking.

## 8. Edge cases handled

| Case | Mechanism |
|------|-----------|
| **Native Windows / SMB shares / containers** (no symlinks) | `--bundle-agents copy` copies files; `doctor` compares by hash (AC-7, AC-14) |
| **WSL** (symlink-capable — fixes nit 16) | Default symlink mode works; do NOT auto-default to copy |
| **CI / offline** | `--offline` + `~/.specforge/cache/` populated by `fetch`/`link` (AC-15) |
| **Teammate first clone** | `.specforge-version` in repo; `specforge link` fetches + wires (AC-8) |
| **iCloud/OneDrive `~/.specforge`** | `doctor` `detect_cloud_sync()` warns (not fails); recommends `--bundle-agents copy` (important 8) |
| **Divergent pins** | `doctor` `scan_sibling_pins()` warns; `link` never moves `current` so projects don't fight (AC-21) |
| **Interrupted upgrade** | `.incomplete` sentinel + idempotent re-run converges (AC-13) |
| **Customized `AGENTS.md`** | overwrite-with-backup; user re-merges from `.specforge/backups/<ts>/` |
| **Ponytail** | baked at release time, not synced at install (ADR-009) |
| **Downgrade** | warns + requires `--force` |
| **Malformed `.specforge-version`** | `doctor` reports as drift (AC-22); `--fix` rewrites from `resolve_harness()` |
| **`cosign` not installed** | exit 3 + install instructions, or `SPECFORGE_ALLOW_UNSIGNED=1` SHA-only fallback (R3) |
| **Deprecated installers** | kept working with banner + delegation (AC-10, §3.x) |
| **CLI vs pin version skew** (fixes nit 17) | CLI reads pin's `VERSION`; wiring deferred to pinned dir's structure (stable for MVP). Forward-compat: newer CLI + older pin = supported. Backward-compat: older CLI + newer pin = best-effort with a version-check warning ("pin <ver> ships features CLI <cli-ver> may not know; consider `self-update`"). |

## 9. ADRs to record (hand to adr-recorder after APPROVED)

- **ADR-006** — Bash CLI as primary; npm/binary deferred
- **ADR-007** — Project symlinks → concrete version dirs; `current` for user-global only; `current` lifecycle owned by `fetch`/`self-update`/`global-pin`
- **ADR-008** — `hooks.json` commands rewritten to absolute paths at `link` time via `jq walk` (command fields only)
- **ADR-009** — Ponytail baked into release tarball (immutable pinned dirs)
- **ADR-010** — `bundle-agents: copy` as first-class mode (native Windows / SMB / containers); mode persisted in `.specforge-mode`

## 10. Risks (for challenger)

- **R1** — Bash portability: `readlink -f` differs on BSD vs GNU; `sha256sum` vs `shasum -a 256`. `detect_platform()` + `sha256()` helpers abstract these. Tested on macOS 12.3+ and Ubuntu 20.04+. Native Windows git-bash: `readlink -f` unsupported → `realpath_resolved()` falls back to `python3 -c "import os,sys;print(os.path.realpath(sys.argv[1]))"` or errors with "use `--bundle-agents copy`".
- **R2** — `AGENTS.md` customization heuristic: **dropped for MVP** (fixes important 13). Always overwrite-with-backup + print backup path. User re-merges from backup. Consistent with §5. TP-004 tests the backup, not a heuristic.
- **R3** — cosign as a dependency: handled in §6 failure contract (exit 3 + install instructions + `SPECFORGE_ALLOW_UNSIGNED=1` SHA-only fallback with warning).
- **R4** — `~/.specforge/<version>/` as a real dir means the CLI must `fetch` even the current version on first install. Mitigation: `init`/`link` call `fetch` transparently if `<pin>/` is missing. No "symlink to the clone you already have" shortcut (would break immutability + verification).

## 11. Out of scope (deferred per REQ-004 §4)

- npm `@specforge/cli` shim (post-MVP)
- Homebrew tap (post-MVP)
- Static Go/Rust binary (post-MVP)
- `.specforge.yml` rich manifest (post-MVP — `.specforge-version` + `.specforge-mode` for MVP)
- Managed-region fences in `AGENTS.md` (post-MVP — overwrite-with-backup for MVP)
- Automated `rollback` command (post-MVP — manual rollback from backups for MVP)
- Codex/OpenCode hook parity (separate roadmap item)

## 12. Challenger R1 resolution

| # | Severity | Issue | Resolution |
|---|---|---|---|
| 1 | Blocking | `current` lifecycle undefined | §1 invariant 2; §3 `fetch` sets if missing, `self-update` advances, new `global-pin` cmd explicit override; `link`/`upgrade` never move it |
| 2 | Blocking | `link` "re-point" ambiguity | §3 `link` step 4: "ensure, never re-point `current`"; errors if `current` missing |
| 3 | Blocking | AC-10 no design home | New §3.x "Deprecated installers": banner + delegation; release workflow prepends banner; `doctor` reports |
| 4 | Blocking | AC-14 copy-mode `upgrade` undesigned | §3 `upgrade` step 9: explicit symlink vs. copy branches; `.specforge-mode` persisted (§2.3) |
| 5 | Blocking | `cache/` never populated | §3 `fetch` step 1+6: writes to `cache/`; `link --offline` reads from `cache/` |
| 6 | Important | `init` pin source ambiguous | §2.1 `resolve_harness()`: env > adjacent VERSION > `current/VERSION` > error; §3 `init` step 2 uses it |
| 7 | Important | doctor substring false-positives | §3 `doctor` step 3: parse `<seg>` from path, exact string compare |
| 8 | Important | cloud-sync unspecified | §3 `doctor` step 6: `realpath` + known-cloud-root check (iCloud, OneDrive, Google Drive, Dropbox); warn not fail |
| 9 | Important | sed corrupts non-path `./` | §4: `jq walk` over `command` fields only, leading `./` only; python3 fallback; error if neither |
| 10 | Important | idempotency vs. backup timestamps | §5: `.incomplete` sentinel; re-run reuses incomplete backup for same source pin |
| 11 | Important | AC-8 failure contract omitted | §6 failure table (SHA→exit1, sig→exit2, no-cosign→exit3, ver-mismatch→exit4, dl-fail→exit5) + cleanup |
| 12 | Important | divergent-pin scan scope undefined | §3 `doctor` step 7: walk `$HOME` depth 4, skip heavy dirs, <2s budget, warn not fail |
| 13 | Important | migrate 90% heuristic untestable | §3 `migrate` step 9: dropped for MVP; always overwrite-with-backup + print path |
| 14 | Important | self-update atomic rename cross-FS | §3 `self-update` step 4: `mktemp -d` adjacent to target, same-FS `mv` |
| 15 | Nit | `init` doesn't handle opencode | §3 `init` step 9: delegates to `link` (covers all platforms uniformly) |
| 16 | Nit | WSL vs. native Windows conflated | §8: WSL = symlink-capable (default); native Windows/SMB/containers = copy |
| 17 | Nit | CLI/pin compat contract unstated | §8 row: forward-compat supported; backward-compat best-effort + warning |
| 18 | Nit | `AGENTS.md` template path unnamed | §3 `init` step 6 + `upgrade` step 10: explicit path `~/.specforge/<pin>/templates/spec-driven-app/AGENTS.md` and `.../cursor-overlay/rules/` |

**Status after R1:** all 5 Blocking resolved in-spec; all 9 Important addressed; all 4 Nits addressed. Ready for user APPROVED → TP-004.
