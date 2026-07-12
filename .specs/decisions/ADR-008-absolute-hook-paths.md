# ADR-008: Rewrite hooks.json commands to absolute paths at link time

**Status**: Accepted (2026-07-12)
**Links**: REQ-004 · ARCH-004

## Context

`hooks/hooks.json` ships with `./hooks/scripts/...` commands relative to the plugin cwd. Under `~/.specforge/<pin>/`, cwd is not guaranteed when Cursor loads hooks.

## Decision

At `specforge link`, rewrite `hooks.json` `command` fields: replace leading `./` with the absolute harness dir (`$HARNESS_DIR/`). Use `jq walk` when available; `python3 json` fallback; error if neither.

`doctor` flags any remaining `"command": "./` as drift; `--fix` rewrites.

## Rationale

Relative hook commands break under versioned, non-cwd harness locations. Absolute paths are deterministic.

## Consequences

- `jq` or `python3` required for safe rewrite in symlink mode.
- Copy mode projects may keep cwd-relative hooks if hooks are project-local (deferred parity).
