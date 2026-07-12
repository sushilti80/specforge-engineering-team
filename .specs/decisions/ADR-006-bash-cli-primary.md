# ADR-006: Bash CLI as primary SpecForge distribution

**Status**: Accepted (2026-07-12)
**Links**: REQ-004 · ARCH-004

## Context

SpecForge ships markdown agents, skills, hooks, and shell scripts. Adopters need install, upgrade, migrate, and drift detection without manual symlink surgery.

## Decision

Ship `scripts/specforge.sh` as the primary distribution channel for MVP. Defer npm (`@specforge/cli`), Homebrew, and static binaries until the bash CLI stabilizes.

## Rationale

- The artifact is mostly markdown and shell — no Node runtime justified for MVP.
- Bash + coreutils runs on macOS, Linux, and WSL without extra installs.
- A single script is auditable (supply-chain: read before `self-update`).
- npm discoverability is real but secondary; bash CLI can be curl-piped from GitHub Releases.

## Consequences

- Windows native users use `--bundle-agents copy` (see ADR-010).
- Release pipeline must publish `specforge.sh` + content tarball per tag.
- Future npm/Homebrew shims can wrap the same commands.
