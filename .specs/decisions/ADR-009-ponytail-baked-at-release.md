# ADR-009: Ponytail baked into release tarball

**Status**: Accepted (2026-07-12)
**Links**: REQ-004 · ARCH-004

## Context

`install-all.sh` runs `sync-ponytail.sh` at install time. Pinned version dirs under `~/.specforge/<ver>/` must be immutable — install-time sync would mutate pinned content.

## Decision

Run `sync-ponytail.sh` in the GitHub Actions release workflow **before** building `specforge-content-<ver>.tar.gz`. Do not sync Ponytail at `specforge link` or `fetch` time.

## Rationale

Immutable pinned dirs are reproducible. A project pinning `2.0.1` always gets the same Ponytail snapshot.

## Consequences

- Release workflow must include Ponytail sync step.
- Harness developers editing Ponytail locally use checkout directly or re-run release build.
