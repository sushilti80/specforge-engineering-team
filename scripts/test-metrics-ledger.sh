#!/usr/bin/env bash
# Unit/smoke tests for metrics ledger files_modified recovery.
# Usage: bash scripts/test-metrics-ledger.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$ROOT/tmp/sf-metrics-test"
PROJECT="$TEST_ROOT/project"
LEDGER_DIR="$PROJECT/.agents/memory/_project/metrics"
PY="$ROOT/hooks/scripts/metrics_ledger.py"
AFTER="$ROOT/hooks/scripts/after-spec-edit.sh"
STOP="$ROOT/hooks/scripts/subagent-stop.sh"

rm -rf "$TEST_ROOT"
mkdir -p "$LEDGER_DIR" "$PROJECT/src" "$PROJECT/.specs/requirements"

echo "== edits buffer claim when modified_files empty =="
python3 - <<PY
import json, os, sys
sys.path.insert(0, "$ROOT/hooks/scripts")
from metrics_ledger import record_file_edit, log_subagent_complete

cwd = "$PROJECT"
record_file_edit(cwd, "$PROJECT/src/a.ts", {"conversation_id": "c1"})
record_file_edit(cwd, "$PROJECT/src/b.ts", {"conversation_id": "c1"})
record_file_edit(cwd, "$PROJECT/.specs/requirements/REQ-001.md", {"conversation_id": "c1"})

modified = log_subagent_complete({
    "status": "completed",
    "subagent_type": "backend-engineer",
    "cwd": cwd,
    "conversation_id": "c1",
    "modified_files": [],
    "duration_ms": 5000,
})
assert len(modified) == 3, modified
ledger = "$LEDGER_DIR/session.jsonl"
rows = [json.loads(l) for l in open(ledger) if l.strip()]
assert rows[-1]["files_modified"] == 3, rows[-1]
assert rows[-1]["files_source"] == "edits_buffer", rows[-1]
assert rows[-1]["spec_touch"] is True, rows[-1]
print("OK edits_buffer claim")
PY

echo "== hook modified_files preferred over buffer =="
python3 - <<PY
import json, sys
sys.path.insert(0, "$ROOT/hooks/scripts")
from metrics_ledger import record_file_edit, log_subagent_complete

cwd = "$PROJECT"
record_file_edit(cwd, "$PROJECT/src/ignored.ts", {})
modified = log_subagent_complete({
    "status": "completed",
    "subagent_type": "frontend-engineer",
    "cwd": cwd,
    "modified_files": ["$PROJECT/src/real.tsx"],
})
assert modified == ["$PROJECT/src/real.tsx"], modified
row = [json.loads(l) for l in open("$LEDGER_DIR/session.jsonl") if l.strip()][-1]
assert row["files_source"] == "hook", row
assert row["files_modified"] == 1, row
print("OK hook preference")
PY

echo "== after-spec-edit records app code + journals specs =="
printf '%s' "{\"cwd\":\"$PROJECT\",\"file_path\":\"$PROJECT/src/app.py\"}" | python3 "$AFTER" >/dev/null
printf '%s' "{\"cwd\":\"$PROJECT\",\"file_path\":\"$PROJECT/.specs/requirements/REQ-002.md\"}" | python3 "$AFTER" >/dev/null
test -f "$LEDGER_DIR/edits.jsonl"
grep -q 'src/app.py' "$LEDGER_DIR/edits.jsonl"
grep -q 'REQ-002' "$PROJECT/.agents/memory/_project/learning-journal.md"
echo "OK after-spec-edit dual path"

echo "== subagent-stop claims buffered edits =="
out="$(
  printf '%s' "{\"cwd\":\"$PROJECT\",\"subagent_type\":\"backend-engineer\",\"status\":\"completed\",\"loop_count\":0,\"modified_files\":[]}" \
    | python3 "$STOP"
)"
echo "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert "Gate checkpoint" in d.get("followup_message",""), d; print("OK stop followup")'
python3 - "$LEDGER_DIR/session.jsonl" <<'PY'
import json, sys
rows = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
r = rows[-1]
assert r["files_modified"] >= 1, r
assert r["files_source"] == "edits_buffer", r
print("OK stop claim", r["files_modified"])
PY

echo "ALL metrics ledger tests passed"
