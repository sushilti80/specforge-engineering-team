# ADR-007: Project symlinks resolve to concrete version dirs

**Status**: Accepted (2026-07-12)
**Links**: REQ-004 · ARCH-004

## Context

User-global SpecForge wiring historically pointed at a single harness clone. Upgrading the clone silently changed agent definitions for all projects. Projects had no version pin.

## Decision

- Store harness versions at `~/.specforge/<MAJOR.MINOR.PATCH>/` (real directories).
- Maintain `~/.specforge/current` as the **user-global** pointer only.
- **Project-local** symlinks resolve to `~/.specforge/<pin>/...` (concrete), never `current`.
- `current` lifecycle: set by `fetch` on first install; advanced by `self-update` or `global-pin`; never moved by project-scoped commands (`init`, `link`, `upgrade`, `migrate`).

## Rationale

Prevents a global upgrade from silently re-pointing pinned projects — the core disease REQ-004 fixes.

## Consequences

- Each project carries `.specforge-version` (one-line pin).
- `doctor` validates concrete resolution; substring false-positives avoided via exact segment match.
- Divergent pins across projects are warned (AC-21), not auto-unified.
