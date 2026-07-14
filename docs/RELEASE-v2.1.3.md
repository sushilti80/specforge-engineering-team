# SpecForge Engineering Team v2.1.3

**Release date:** 2026-07-14  
**Type:** Patch (Cursor `files_modified` recovery via edits buffer)  
**Previous:** [v2.1.2](https://github.com/sushilti80/specforge-engineering-team/releases/tag/v2.1.2)

## Summary

Fixes empty `files_modified` on Cursor `subagentStop` when the payload omits `modified_files`. After-file-edit hooks now record every edit into `edits.jsonl`; on subagent stop the ledger claims pending paths so session metrics show real file counts.

## Changes

### `metrics_ledger.py`

- Buffer file edits (`edits_buffer` / `claim_pending_edits`) from `afterFileEdit` → `edits.jsonl`
- Recover `files_modified` when Cursor sends an empty `modified_files` list
- Record `files_source` and `files_sample` for auditability

### `after-spec-edit.sh`

- Record **all** file edits to `edits.jsonl` (still journals specs/memory as before)

### `subagent-stop.sh`

- Use the modified list returned by the ledger claim (no double-claim)

### `hooks/adapters/bridge.py`

- Broader `modified_files` alias extraction for adapter payloads

### Docs / tests

- `ENGINEERING-METRICS.md` + metrics README notes on the Cursor gap and buffer recovery
- `scripts/test-metrics-ledger.sh` — coverage for claim / buffer path

## Upgrade

```bash
cd specforge-engineering-team
git pull
bash scripts/specforge.sh install-local --pin 2.1.3
bash scripts/specforge.sh global-pin 2.1.3
# in each project:
bash scripts/specforge.sh link   # or upgrade --pin 2.1.3
```

Or reinstall platform hooks via `scripts/install-all.sh` / `install-*.sh`.

## Accepted limitation

Recovery depends on `afterFileEdit` (or adapter equivalents) firing during the subagent turn. Platforms that never emit per-edit events still report zero until their adapters write the buffer.
