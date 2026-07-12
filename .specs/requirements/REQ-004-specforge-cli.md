# REQ-004: SpecForge CLI — packaging, install, upgrade, doctor

**Status**: Approved (2026-07-12, user) — Q1/Q2 PASS; ARCH-004 R1 drafted (READY_FOR_APPROVAL)
**Date**: 2026-07-12 · **Owner**: requirements-analyst (draft) / **User** (APPROVED) · **Links**: ARCH-004 (R1, pending APPROVED) · TP-004 (pending) · ADR-006..010 (pending)
**Challenger R1**: C1–C3 Blocking resolved in-spec; C4–C10 Important/Nit addressed; see §9.
**Q1/Q2 smoke (2026-07-12)**: BOTH PASS (user-confirmed). Symlink strategy confirmed for Cursor + Claude + OpenCode.

## 1. Problem

Maintainers and adopters of SpecForge (the harness) cannot bootstrap or upgrade a project without manual, error-prone steps:

- **Fragile symlinks** — `install-*.sh` symlinks the harness clone into per-tool user dirs using an **absolute path** into a cloud-synced folder (iCloud/OneDrive). Moving the clone breaks every install.
- **No per-project version pin** — a bootstrapped project has no way to declare "I expect SpecForge vX.Y.Z." Upgrades are guesswork.
- **Manual merge on upgrade** — `bootstrap-project.sh` skips existing files, so v2 templates don't reach old projects. Adopters must hand-edit `AGENTS.md`, `.cursor/rules/*.mdc`, and re-link Claude/OpenCode agents.
- **`SPECFORGE_HOME` placeholder** — agents/rules reference `SPECFORGE_HOME/...` as a literal string; tools don't resolve it, so adopters must create project-local `.specforge/` symlinks by hand.

The pain is real: upgrading `sales_architect` from v1.x → v2.0.1 took four commits, ~90 files, and several "did we update Claude too?" rounds.

## 2. User Stories

- As a **new adopter**, I want to bootstrap SpecForge in my app in one command, so that I'm running `/eng-orchestrator` within 5 minutes.
- As an **existing adopter**, I want to upgrade my project to a newer SpecForge version without manually merging templates or re-linking agents, so that upgrades are not a half-day chore.
- As a **maintainer**, I want each project to pin the SpecForge version it expects, so that drift is detectable and reproducible.
- As a **teammate** cloning a SpecForge-using repo, I want a single post-clone command that wires my machine to the pinned version, so that I don't hit dangling symlinks.
- As a **CI runner**, I want to install a specific SpecForge version offline from a cache, so that ephemeral runners don't depend on network at runtime.
- As a **Windows / no-Node user**, I want an install path that doesn't require symlinks or Node, so that I'm not locked out.

## 3. Acceptance Criteria (testable; becomes TP-004)

- **AC-1** — Given a fresh empty project dir, when I run `specforge init . --platform cursor,claude --tier 1`, then `AGENTS.md`, `.specforge-version`, `.agents/memory/_project/MEMORY.md`, `.specs/README.md`, and the requested platform overlays exist, and `.specforge/` symlinks resolve to the currently installed harness version.
- **AC-2** — Given a project with `.specforge-version` pinning `2.0.1`, when I run `specforge doctor`, then every project-local agent/skill/doc symlink resolves to `~/.specforge/2.0.1/...` (not `current`), and any link resolving to a different version is reported as drift.
- **AC-3** — Given `specforge link` has run, when Cursor loads hooks, then `hooks.json` `command` fields resolve to absolute paths under the pinned version dir (no `./`-relative commands remain).
- **AC-4** — Given an old project bootstrapped on v1.x with no manifest, when I run `specforge migrate`, then a `.specforge-version` file is written, stale copied Claude/OpenCode agents are replaced with symlinks to the concrete version dir, and `.specs/` + `.agents/memory/` content is preserved byte-for-byte.
- **AC-5** — Given `specforge upgrade --pin 2.1.0` on a project pinning `2.0.1`, when the command completes, then project-local symlinks point at `~/.specforge/2.1.0/...`, `.specforge-version` reads `2.1.0`, and `AGENTS.md`/`.cursor/rules/*.mdc` are updated with a documented merge policy (managed-region fences or overwrite-with-backup).
- **AC-6** — Given `specforge doctor --fix` on a project with one dangling symlink and one version-mismatched link, when it runs, then the dangling link is re-pointed to the pinned version dir, the mismatched link is corrected, and a report lists what changed.
- **AC-7** — Given a Windows machine (no symlink privilege), when I run `specforge init . --bundle-agents copy --platform cursor`, then agent/skill files are **copied** (not symlinked) into the project, and `doctor` reports them as copies, not broken symlinks.
- **AC-8** — Given a teammate clones a repo containing `.specforge-version: 2.0.1` but has no `~/.specforge/2.0.1/` locally, when they run `specforge link`, then the missing version is fetched from the GitHub Release tarball, **SHA256-verified AND signature-verified against the published cosign public key** (sigstore), extracted to `~/.specforge/2.0.1/`, and project symlinks are created. On signature mismatch: abort with non-zero exit, do not extract, print the expected vs actual SHA256.
- **AC-9** — Given `specforge status` in any project, when I run it, then it prints: pinned version, installed local versions, per-platform link state, and drift summary — **≤ 50 lines by default**; full drift detail behind `status --verbose`; exit code non-zero iff drift present.
- **AC-10** — Given the existing `install-all.sh` + `bootstrap-project.sh` scripts, when a user runs them, then they still work (deprecation warning only, not removed) so no-CLI users are not broken.
- **AC-11** (`migrate`/`upgrade` dry-run) — Given any project, when I run `specforge migrate --dry-run` or `specforge upgrade --pin X --dry-run`, then it prints every planned deletion, overwrite, and symlink creation **without mutating** the filesystem.
- **AC-12** (`migrate`/`upgrade` backup) — Given `specforge migrate` or `upgrade` mutates files, when it runs, then every deleted or overwritten file is copied to `.specforge/backups/<ISO8601-ts>/` first, and the backup path is printed at completion.
- **AC-13** (`migrate`/`upgrade` idempotent re-run) — Given an interrupted `migrate`/`upgrade` (Ctrl-C, disk full, EACCES), when re-run, then it converges to the same end state as a single uninterrupted run (no partial state, no duplicate backups of backups).
- **AC-14** (copy-mode `upgrade`/`doctor`) — Given a `bundle-agents: copy` project (Windows/share/container), when `upgrade` runs, then changed files are re-copied from `~/.specforge/<pin>/`; when `doctor --fix` runs, then files whose content hash differs from the pinned version are re-copied and reported as `re-copied` (not `re-pointed`).
- **AC-15** (offline / CI cache) — Given `SPECFORGE_OFFLINE=1` (or `--offline`) and a populated `~/.specforge/cache/<ver>.tgz`, when `specforge link` runs, then the version is extracted from cache with no network access attempted; given offline and missing-from-cache, then `link` exits non-zero with a message naming the missing version and cache path.
- **AC-16** (`init` on non-empty / already-bootstrapped project) — Given a project that already contains `.specforge-version` matching the installed version, when `specforge init .` runs, then it is a no-op for managed files and prints `already bootstrapped at <ver>`; given a pin mismatch, it refuses unless `--force` and recommends `specforge upgrade --pin <installed>`.
- **AC-17** (`self-update`) — Given `specforge self-update`, when it runs, then it downloads the new `specforge.sh` from the GitHub Release matching `current`, verifies SHA256 + cosign signature, writes to a tmp file, and atomically renames over the installed script (never in-place overwrite of the running script).
- **AC-18** (`fetch <ver>`) — Given `specforge fetch 2.0.1`, when it runs, then version `2.0.1` is downloaded + verified + extracted to `~/.specforge/2.0.1/` **without** moving `current` or touching any project.
- **AC-19** (`versions`) — Given `specforge versions`, when it runs, then it lists all versions under `~/.specforge/`, marks `current`, and marks versions referenced by any project manifest in the current directory or its parents.
- **AC-20** (`unlink`) — Given `specforge unlink`, when it runs, then all project-local symlinks to `~/.specforge/` are removed; `.specs/` and `.agents/memory/` are untouched; `.specforge-version` is preserved (so re-link is possible).
- **AC-21** (divergent-pin warning) — Given two SpecForge-using projects with divergent `.specforge-version` pins on the same machine, when `specforge status` or `doctor` runs in either, then it warns: `N SpecForge projects detected with divergent pins (<list>); simultaneous Cursor windows may load inconsistent agent definitions.`
- **AC-22** (`.specforge-version` format contract) — Given any `.specforge-version` file, when `doctor` reads it, then it accepts exactly one semver string `MAJOR.MINOR.PATCH` with optional trailing newline, no `v` prefix, no ranges; malformed pins are reported as drift.

## 4. Scope

**In (v2.1 — bash CLI MVP):**
- `scripts/specforge.sh` — single CLI entry point
- `VERSION` file at harness root (single source of truth, read from `plugin.json`)
- `.specforge-version` per project (one-line pin; `.specforge.yml` deferred until schema stabilizes)
- Commands: `init`, `link`, `upgrade --pin X`, `migrate`, `doctor [--fix|--dry-run]`, `status`, `unlink`, `fetch <ver>`, `versions`, `self-update`
- Canonical harness location: `~/.specforge/<version>/` + `current` symlink (user-global only)
- Project-local symlinks resolve to **concrete version dir** (not `current`)
- `hooks.json` command paths rewritten to absolute on `link`
- `bundle-agents: copy` mode for Windows / network shares / containers
- Ponytail baked into release tarball (not synced at install)
- GitHub Actions tag-triggered release: content tarball + SHA256 + sigstore
- Deprecation warnings on old `install-*.sh` / `bootstrap-project.sh` (kept working)

**Non-goals (deferred):**
- npm package (`@specforge/cli` shim) — secondary channel, post-MVP
- Homebrew tap — secondary, post-MVP
- Static Go/Rust binary embedding content — post-MVP (bash CLI first; binary if drift class proves real)
- `.specforge.yml` rich manifest with `manifest_version:` — defer until bash CLI stabilizes; `.specforge-version` one-liner for MVP
- GUI / TUI
- Auto-update of `AGENTS.md` custom edits (managed-region fence spec deferred; MVP uses overwrite-with-backup + diff prompt)
- Codex/OpenCode hook parity (separate roadmap item)
- Paid/private gating

## 5. Constraints & Assumptions

**Constraints:**
- Must run on macOS, Linux, WSL without Node (bash + standard coreutils only for MVP)
- Must not break existing `install-*.sh` / `bootstrap-project.sh` users (deprecation path, not removal)
- Must preserve `.specs/` and `.agents/memory/` content during any upgrade/migrate (these are project-owned, never touched)
- Harness version source of truth = `plugin.json` `version` field → `VERSION` file at build time. No second version file.
- Project-local symlinks MUST resolve to concrete version dirs, never `current` (else global upgrade silently re-points pinned projects — the disease we're fixing)
- `hooks.json` MUST NOT ship `./`-relative commands after `link` runs
- **Release signing: cosign/sigstore for MVP.** The tarball is executable agent content; SHA256-only is insufficient against a compromised release pipeline. AC-8 and AC-17 require signature verification. Q5 resolved: signing is in-scope for MVP.
- **`AGENTS.md` merge policy: overwrite-with-backup for MVP.** Managed-region fences deferred to post-MVP. `upgrade` writes the user's old `AGENTS.md` to `.specforge/backups/<ts>/` before overwriting, and prints the backup path. Users who customized `AGENTS.md` re-merge by hand from the backup. Q3 resolved: overwrite-with-backup now, fences later.
- **`.specforge-version` format: exactly one semver `MAJOR.MINOR.PATCH`, optional trailing newline, no `v` prefix, no ranges.** Malformed = drift (AC-22).
- **Fallback if Cursor does not follow two-hop symlinks (Q1 smoke):** `link` copies the plugin dir on Cursor (not symlinks); symlink strategy reserved for Claude/OpenCode. This constraint activates only if Q1 smoke fails — record the result before ARCH-004.
- **Q1/Q2 smoke results (2026-07-12):** **BOTH PASS — confirmed by user.** Q1: Cursor loads plugin through three-hop symlink chain (`specforge-smoke-test → ~/.specforge/current → ~/.specforge/2.0.1 → <harness>`). Q2: Claude Code follows two-hop agent symlinks. **Symlink strategy confirmed for all tools (Cursor, Claude, OpenCode).** Fallback constraint (copy-on-Cursor) does **not** activate. ARCH-004 proceeds with symlink-first design; `bundle-agents: copy` remains available for Windows/shares/containers but is not the default path.

**Risky assumptions (flag for challenger):**
- **A1** — Tools (Cursor, Claude, OpenCode) reliably follow symlinks into `~/.specforge/<version>/`. Cursor plugin model copies files; does it follow a symlinked plugin dir? Needs smoke test before ARCH.
- **A2** — `~/.specforge/` is not iCloud-synced by default on macOS. True today, but `doctor` must detect if a user relocated it under cloud sync.
- **A3** — Bash CLI is sufficient for MVP; no Node runtime needed. Reviewers agreed, but `npx` discoverability is a real adoption lever — is deferring npm costing us users?
- **A4** — Overwrite-with-backup for `AGENTS.md` on upgrade is acceptable for MVP. May infuriate users who customized it. Managed-region fences (developer's suggestion) might be needed sooner than "post-MVP."
- **A5** — Ponytail can be baked at release time into an immutable tarball. Requires CI to run `sync-ponytail.sh` before building the tarball; current `install-all.sh` syncs at install time — incompatible with pinned immutable dirs.
- **A6** — Two Cursor windows with different project pins will load different agent definitions from the same named agent (global vs project-local). Documented limitation, not solved, for MVP.

## 6. Open Questions

- [x] **Q1** — Does Cursor follow a symlinked plugin dir? **PASS (2026-07-12, user-confirmed):** Cursor loads plugin through three-hop symlink chain. Symlink strategy confirmed for all tools.
- [x] **Q2** — Does Claude Code follow `~/.claude/agents/*.md` symlinks? **PASS (2026-07-12):** Two-hop chain resolves; Claude already follows one-hop today. Confirmed.
- [ ] ~~Q3~~ — **Resolved:** overwrite-with-backup for MVP; managed-region fences deferred (see §5).
- [ ] ~~Q4~~ — **Resolved for MVP:** `.specforge-version` one-liner (AC-22 format). `.specforge.yml` with `manifest_version:` deferred until bash CLI stabilizes.
- [ ] ~~Q5~~ — **Resolved:** cosign/sigstore signing in-scope for MVP (see §5, AC-8, AC-17).
- [ ] **Q6** — **Resolved:** `self-update` re-downloads `specforge.sh` from GitHub Release with SHA256+sig verification, atomic tmp+rename (AC-17).

## 7. Decisions to Record

Hand to `adr-recorder` after APPROVED:

- **ADR-006** — Bash CLI as primary distribution; npm/binary deferred (rationale: artifact is markdown+shell, no Node runtime justified for MVP)
- **ADR-007** — Project symlinks resolve to concrete version dirs; `current` reserved for user-global (rationale: prevent silent re-pointing of pinned projects on global upgrade)
- **ADR-008** — `hooks.json` commands rewritten to absolute paths at `link` time (rationale: `./`-relative breaks under versioned harness location)
- **ADR-009** — Ponytail baked into release tarball, not synced at install (rationale: pinned version dirs are immutable)
- **ADR-010** — `bundle-agents: copy` as first-class mode for Windows/shares/containers (rationale: symlinks not portable everywhere)

## 8. Reviewer context (three-panel review)

This REQ incorporates findings from three independent subagent reviews (release engineer, technologist, developer). Key converged corrections baked into this REQ:

1. **npm-as-primary dropped** — all three flagged Node runtime tax on a markdown artifact
2. **Concrete-version-dir links** — release engineer's load-bearing fix for the `current`-hop disease
3. **Absolute hook paths** — release engineer's catch on `hooks.json` cwd-relative commands
4. **`migrate` command** — developer's explicit ask for the `sales_architect` pre-manifest case
5. **Missing commands** — `status`, `unlink`, `fetch`, `versions`, `self-update`, `doctor --fix/--dry-run` (developer)
6. **Ponytail release-time bake** — release engineer (immutable pinned dirs)
7. **`bundle-agents: copy`** — release engineer (Windows/shares/containers)

Full reviewer transcripts: agents `b07babba` (release eng), `4f8633c8` (technologist), `3731dbee` (developer).

## 9. Challenger R1 resolution

**Reviewer:** challenger subagent `7810b2f7`. **Round 1.** Approval was blocked on C1–C3.

| ID | Severity | Objection (summary) | Resolution |
|----|----------|---------------------|------------|
| C1 | Blocking | Supply-chain: AC-8 said SHA256 but Q5 left signing open; installer auto-fetches executable agent content | **Resolved:** Q5 closed — cosign/sigstore in-scope for MVP (§5); AC-8 rewritten to require SHA256 + signature verification |
| C2 | Blocking | `migrate`/`upgrade` destructive with no dry-run/backup/rollback/idempotency | **Resolved:** added AC-11 (dry-run), AC-12 (backup to `.specforge/backups/<ts>/`), AC-13 (idempotent re-run); Q3 closed — overwrite-with-backup for MVP |
| C3 | Blocking | READY_FOR_APPROVAL but A1/Q1/Q2 admit Cursor two-hop-symlink is unverified | **Resolved:** status downgraded to `Draft (pending Q1/Q2 smoke)`; fallback constraint added to §5 (copy on Cursor if smoke fails); Q1 smoke now a hard gate before ARCH-004 |
| C4 | Important | Copy-mode `upgrade`/`doctor` undescribed | **Resolved:** added AC-14 |
| C5 | Important | CI offline story has no AC | **Resolved:** added AC-15 |
| C6 | Important | `init` on non-empty project undefined | **Resolved:** added AC-16 |
| C7 | Important | `self-update`/`fetch`/`versions`/`unlink` in scope but no ACs | **Resolved:** added AC-17, AC-18, AC-19, AC-20 |
| C8 | Important | Divergent-pin limitation unsurfaced | **Resolved:** added AC-21 |
| C9 | Important | AC-9 "under 50 lines" self-contradictory with drift | **Resolved:** AC-9 rewritten — ≤50 lines default, `--verbose` for full drift, non-zero exit on drift |
| C10 | Nit | `.specforge-version` no format contract | **Resolved:** added format constraint to §5 + AC-22 |

**Round 2:** not requested. Presenting to **user** for APPROVED per v2 doctrine.
