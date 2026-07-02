---
name: spec-vendor-sync
description: >-
  Checklist for syncing third-party skills into the harness (e.g. ponytail).
  Use before commit or when running scripts/sync-ponytail.sh. Ensures real
  files under skills/, not broken symlinks in bootstrapped projects.
disable-model-invocation: true
---

# Spec vendor sync

Run: `bash scripts/sync-<vendor>.sh` (e.g. `sync-ponytail.sh`).

## Pre-sync

- [ ] Upstream license compatible (MIT/Apache/etc.)
- [ ] Record upstream URL in `vendor/<name>/SOURCE.md`

## Post-sync checklist (must pass)

- [ ] `skills/<name>/SKILL.md` is a **real file** (not symlink to `vendor/` only)
- [ ] Bootstrapped projects get skills via `.agents/skills/` copy/symlink to **harness** `skills/` — test: `test -f skills/<name>/SKILL.md`
- [ ] Cursor rule copied to `rules/` and `templates/.../cursor-overlay/rules/` if applicable
- [ ] `vendor/<name>/VERSION` contains upstream commit short SHA
- [ ] `install-all.sh` or docs mention refresh command
- [ ] No nested `.git` under `vendor/` committed

## Anti-patterns

- Symlink `skills/foo` → `../vendor/foo/skills/foo` **without** copying into `skills/` (breaks bootstrap)
- Pasting full upstream README into chat during sync (use script output only)

## Verify

```bash
bash scripts/sync-ponytail.sh
test -f skills/ponytail/SKILL.md && ! test -L skills/ponytail/SKILL.md || test -f skills/ponytail/SKILL.md
ls -la skills/ponytail/
```

Recipe: **`vendor-sync`** (meta) — see ENGINEERING-RECIPES.md.
