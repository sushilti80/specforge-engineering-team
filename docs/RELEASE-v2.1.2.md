# SpecForge Engineering Team v2.1.2

**Release date:** 2026-07-13  
**Type:** Patch (metrics script hardening for multi-harness fidelity)  
**Previous:** [v2.1.1](https://github.com/sushilti80/specforge-engineering-team/releases/tag/v2.1.1)

## Summary

Hardens project-runtime metrics helpers so release token estimates and efficiency proxies behave correctly across harnesses and short/noisy app repos. Closes gaps that hurt multi-harness fidelity (bad `--since`, unfiltered ledgers, weak CLI UX).

## Changes

### `estimate-pipeline-tokens.sh`

- Proper `--help` / usage with recipes and options
- `--project DIR` to estimate from an app root
- Warn on unknown tier / unknown agent names; clearer invalid `--tier` handling
- Prefer `--agents` as source of truth (minimal/ceiling tables are heuristics)

### `collect-release-metrics.sh`

- Fail loud on invalid `--since` (wrong harness tag, missing ref, non-git cwd)
- Filter `session.jsonl` by event `ts` when `--since` resolves to a commit time
- Clamp default `HEAD~N` when the repo has fewer than N commits
- Clearer empty-ledger / no-events-in-range messaging
- Notes that ledger fidelity needs SpecForge hooks (Cursor / Claude / Codex / Copilot adapters)

### Accepted limitation

ForgeCode and OpenCode still do not write `session.jsonl`. Git diff + gate checkpoint sections work; subagent run counts remain partial on those platforms until ledger adapters land.

## Upgrade

```bash
cd specforge-engineering-team
git pull
bash scripts/install-all.sh   # or platform-specific install-*.sh
```

Existing projects (re-bootstrap or copy once):

```bash
bash scripts/bootstrap-project.sh /path/to/project
# Bootstrap may skip-if-exists for scripts — force overwrite metrics helpers:
cp scripts/{estimate-pipeline-tokens,collect-release-metrics}.sh /path/to/project/scripts/
```
