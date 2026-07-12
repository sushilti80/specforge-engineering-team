# ADR-010: bundle-agents copy as first-class mode

**Status**: Accepted (2026-07-12)
**Links**: REQ-004 · ARCH-004

## Context

Symlinks are not portable on native Windows, SMB shares, and some containers. WSL has full symlink support.

## Decision

- `specforge init --bundle-agents copy` copies agent/skill/doc files into the project instead of symlinking.
- Persist mode in `.specforge-mode` (`symlink` or `copy`).
- `upgrade` and `doctor --fix` re-copy (hash-compare) in copy mode; `upgrade` re-points in symlink mode.
- WSL defaults to symlink mode; native Windows / shares / containers use copy.

## Rationale

No user locked out by platform symlink limitations. Doctor can detect drift via hash in copy mode.

## Consequences

- Copy-mode projects do not get user-global wiring (each project owns copies).
- Upgrade must branch on `.specforge-mode` (AC-14).
