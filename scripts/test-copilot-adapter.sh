#!/usr/bin/env bash
# Smoke + fixture tests for the Copilot SpecForge adapter (bridge + install + bootstrap).
# Usage: bash scripts/test-copilot-adapter.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$ROOT/tmp/sf-copilot-test"
COPILOT_HOME="$TEST_ROOT/copilot"
AGENTS_SKILLS_HOME="$TEST_ROOT/agents-skills"
BRIDGE="$ROOT/hooks/adapters/bridge.py"
PROJECT="$TEST_ROOT/project"
BOOTSTRAP_PROJECT="$TEST_ROOT/bootstrap-project"

rm -rf "$TEST_ROOT"
mkdir -p "$COPILOT_HOME" "$PROJECT/.specs" "$PROJECT/.agents/memory/_project"

cat > "$PROJECT/.agents/memory/_project/MEMORY.md" <<'EOF'
# Project memory
- **Name:** copilot-test-app
- **Stack:** bash + python
EOF

# ---------------------------------------------------------------------------
# bridge: copilot outputs flat additionalContext (no hookSpecificOutput wrap)
# ---------------------------------------------------------------------------
echo "== bridge: sessionStart (copilot) =="
out="$(
  cd "$PROJECT" && printf '%s' '{"cwd":"'"$PROJECT"'","hookEventName":"sessionStart"}' \
    | python3 "$BRIDGE" --platform copilot --script session-start.sh --event sessionStart --specforge
)"
echo "$out" | python3 -c '
import json,sys
d=json.load(sys.stdin)
ctx=d.get("additionalContext","")
assert "Spec-driven" in ctx or "Principle 8" in ctx, d
# Copilot never wraps in hookSpecificOutput
assert "hookSpecificOutput" not in d, d
print("OK sessionStart copilot")
'

echo "== bridge: userPromptSubmitted advisory (copilot) =="
out="$(
  printf '%s' '{"cwd":"'"$PROJECT"'","prompt":"Should we compare feasibility? advisory only"}' \
    | python3 "$BRIDGE" --platform copilot --script prompt-intent.sh --event userPromptSubmitted --specforge
)"
echo "$out" | python3 -c '
import json,sys
d=json.load(sys.stdin)
ctx=d.get("additionalContext","")
assert "ADVISORY" in ctx or "advisory" in ctx.lower(), d
assert "hookSpecificOutput" not in d, d
print("OK userPromptSubmitted copilot")
'

echo "== bridge: postToolUse after-spec-edit (copilot) =="
out="$(
  printf '%s' '{"cwd":"'"$PROJECT"'","tool_input":{"file_path":"'"$PROJECT"'/.specs/requirements/REQ-001.md"}}' \
    | python3 "$BRIDGE" --platform copilot --script after-spec-edit.sh --event postToolUse --specforge
)"
echo "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d=={} or "additionalContext" in d; print("OK postToolUse copilot")'
journal="$PROJECT/.agents/memory/_project/learning-journal.md"
test -f "$journal"
grep -q 'REQ-001' "$journal"
echo "OK copilot learning-journal append"

echo "== bridge: subagentStop followup (copilot) =="
out="$(
  printf '%s' '{"cwd":"'"$PROJECT"'","agentName":"eng-orchestrator","status":"completed","stop_hook_active":false}' \
    | python3 "$BRIDGE" --platform copilot --script subagent-stop.sh --event subagentStop --specforge
)"
echo "$out" | python3 -c '
import json,sys
d=json.load(sys.stdin)
# subagentStop emits a followup → copilot flat additionalContext
ctx=d.get("additionalContext","")
assert "Gate checkpoint" in ctx, d
assert "hookSpecificOutput" not in d, d
print("OK subagentStop copilot")
'

echo "== bridge: agentStop decision block (copilot) =="
out="$(
  printf '%s' '{"cwd":"'"$PROJECT"'","agentName":"eng-orchestrator","stop_hook_active":false}' \
    | python3 "$BRIDGE" --platform copilot --script session-stop.sh --event agentStop --specforge
)"
echo "$out" | python3 -c '
import json,sys
d=json.load(sys.stdin)
# agentStop (maps to Stop) with a followup → copilot decision:block + reason
assert d.get("decision")=="block", d
assert d.get("reason"), d
print("OK agentStop copilot decision:block")
'

# ---------------------------------------------------------------------------
# install-copilot: global CLI install → ~/.copilot/hooks/specforge.json
# ---------------------------------------------------------------------------
echo "== install-copilot hooks merge =="
export COPILOT_HOME AGENTS_SKILLS_HOME
bash "$ROOT/scripts/install-copilot.sh" >/dev/null
python3 - "$COPILOT_HOME/hooks/specforge.json" <<'PY'
import json,sys
with open(sys.argv[1]) as f:
    data=json.load(f)
assert data.get("version")==1, data
hooks=data.get("hooks") or {}
needed=["sessionStart","userPromptSubmitted","subagentStop","postToolUse","agentStop"]
missing=[e for e in needed if e not in hooks]
assert not missing, missing
blob=json.dumps(hooks)
assert "hooks/adapters/bridge.py" in blob
assert "--specforge" in blob
assert "--platform copilot" in blob
# Copilot uses "bash" field, not "command"
assert '"bash"' in blob
# "command" may appear only as the value of "type", never as a key
assert '"command":' not in blob, blob
print("OK copilot specforge.json")
PY

echo "== install-copilot agents use .agent.md suffix =="
test -f "$COPILOT_HOME/agents/eng-orchestrator.agent.md"
echo "OK copilot agent.md naming"

echo "== install-copilot idempotent =="
bash "$ROOT/scripts/install-copilot.sh" >/dev/null
python3 - "$COPILOT_HOME/hooks/specforge.json" <<'PY'
import json,sys
with open(sys.argv[1]) as f:
    data=json.load(f)
hooks=data.get("hooks") or {}
# Count SpecForge sessionStart bash entries — must be exactly 1 after reinstall
count=0
for h in hooks.get("sessionStart") or []:
    if isinstance(h, dict):
        cmd=h.get("bash") or ""
        if "--specforge" in cmd and "session-start.sh" in cmd:
            count+=1
assert count==1, count
print("OK copilot idempotent")
PY

echo "== preserve user hooks on copilot merge =="
python3 - "$COPILOT_HOME/hooks/specforge.json" <<'PY'
import json,sys
path=sys.argv[1]
with open(path) as f:
    data=json.load(f)
data["hooks"].setdefault("sessionStart", []).append({
    "type":"command","bash":"echo user-copilot-hook","timeoutSec":5
})
with open(path,"w") as f:
    json.dump(data,f,indent=2)
    f.write("\n")
PY
bash "$ROOT/scripts/install-copilot.sh" >/dev/null
python3 - "$COPILOT_HOME/hooks/specforge.json" <<'PY'
import json,sys
with open(sys.argv[1]) as f:
    hooks=json.load(f)["hooks"]
cmds=[h.get("bash") or "" for h in hooks.get("sessionStart") or []]
assert any(c=="echo user-copilot-hook" for c in cmds), cmds
assert sum(1 for c in cmds if "--specforge" in c and "session-start.sh" in c)==1, cmds
print("OK copilot user hook preserved")
PY

# ---------------------------------------------------------------------------
# bootstrap --platform copilot: cloud-safe vendoring into .github/
# ---------------------------------------------------------------------------
echo "== bootstrap --platform copilot =="
rm -rf "$BOOTSTRAP_PROJECT"
mkdir -p "$BOOTSTRAP_PROJECT"
bash "$ROOT/scripts/bootstrap-project.sh" --platform copilot "$BOOTSTRAP_PROJECT" >/dev/null

python3 - "$BOOTSTRAP_PROJECT/.github/hooks/specforge.json" <<'PY'
import json,sys
with open(sys.argv[1]) as f:
    data=json.load(f)
assert data.get("version")==1
hooks=data.get("hooks") or {}
needed=["sessionStart","userPromptSubmitted","subagentStop","postToolUse","agentStop"]
missing=[e for e in needed if e not in hooks]
assert not missing, missing
blob=json.dumps(hooks)
# Cloud-safe: relative paths to vendored bridge, no $HOME / absolute plugin paths
assert "scripts/specforge-hooks/bridge.py" in blob, blob
assert "$HOME" not in blob
assert "__SPECFORGE_BRIDGE__" not in blob
print("OK bootstrap copilot hooks (relative paths)")
PY

test -f "$BOOTSTRAP_PROJECT/scripts/specforge-hooks/bridge.py"
test -d "$BOOTSTRAP_PROJECT/scripts/specforge-hooks/scripts"
test -f "$BOOTSTRAP_PROJECT/.github/agents/eng-orchestrator.agent.md"
test -d "$BOOTSTRAP_PROJECT/.github/skills/spec-pipeline"
test -f "$BOOTSTRAP_PROJECT/.github/copilot-instructions.md"
echo "OK bootstrap vendored .github/ + scripts/specforge-hooks/"

# Vendored bridge must actually run with relative paths from project root
echo "== bootstrap: vendored bridge executes =="
out="$(
  cd "$BOOTSTRAP_PROJECT" && printf '%s' '{"cwd":"'"$BOOTSTRAP_PROJECT"'","hookEventName":"sessionStart"}' \
    | python3 scripts/specforge-hooks/bridge.py --platform copilot --script session-start.sh --event sessionStart --specforge
)"
echo "$out" | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert d.get("additionalContext"), d
print("OK vendored bridge runs")
'

echo "PASS: test-copilot-adapter"
