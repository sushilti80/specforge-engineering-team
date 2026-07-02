# Session metrics (SpecForge)

Auto-appended by Cursor hook `subagentStop` when spec-team subagents complete:

- `session.jsonl` — one JSON line per subagent (`agent`, `files_modified`, `spec_touch`)

At release (Tier 2+):

```bash
bash scripts/collect-release-metrics.sh --since v1.2.0
bash scripts/estimate-pipeline-tokens.sh greenfield-feature --tier 2
```

Then skill `spec-release-metrics` → `.specs/metrics/releases/REL-YYYY-MM-DD.yaml`

Playbook: `SPECFORGE_HOME/ENGINEERING-METRICS.md`
