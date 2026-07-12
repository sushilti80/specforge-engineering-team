# SpecForge Engineering Team v2.0.1

**Release date:** 2026-07-11  
**Type:** Patch (anti-leak / Principle 8 hardening)  
**Previous:** [v2.0.0](https://github.com/sushilti80/specforge-engineering-team/releases/tag/v2.0.0)

## Summary

Hardens path-only delegation so conversation summaries and HANDOFF prose are not fed into spawned agents.

## Changes

- **HANDOFF:** “paste into their prompt” → **paths only (do not paste this HANDOFF block)**
- **`eng-orchestrator`:** spawn allowlist template; Tier 2+ isolation for challenger / reviewers / verifier / guardian
- **Playbook + rules:** disk wins over parent chat; no conversation summaries in delegation
- **Isolation roles:** allowed/forbidden inputs on challenger, code-reviewer, security-reviewer, spec-guardian, verifier
- **Hook:** `subagent-stop` nudges “do not attach a chat summary”
- **Fix:** root `rules/spec-driven.mdc` aligned to v2 need-based doctrine (was still teaching full pipeline)

## Upgrade

```bash
git fetch --tags
git checkout v2.0.1
bash scripts/install-all.sh   # or your platform install script
```

Full doctrine remains [v2.0.0 release notes](RELEASE-v2.0.0.md).
