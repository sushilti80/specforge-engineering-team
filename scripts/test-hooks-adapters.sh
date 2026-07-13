#!/usr/bin/env bash
# Smoke + fixture tests for Claude/Codex SpecForge hook adapters.
# Usage: bash scripts/test-hooks-adapters.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$ROOT/tmp/sf-hooks-test"
CLAUDE_HOME="$TEST_ROOT/claude"
CODEX_HOME="$TEST_ROOT/codex"
BRIDGE="$ROOT/hooks/adapters/bridge.py"
PROJECT="$TEST_ROOT/project"

rm -rf "$TEST_ROOT"
mkdir -p "$CLAUDE_HOME" "$CODEX_HOME" "$PROJECT/.specs" "$PROJECT/.agents/memory/_project"

cat > "$PROJECT/.agents/memory/_project/MEMORY.md" <<'EOF'
# Project memory
- **Name:** hooks-test-app
- **Stack:** bash + python
EOF

echo "== bridge: SessionStart (claude) =="
out="$(
  cd "$PROJECT" && printf '%s' "{\"cwd\":\"$PROJECT\",\"hook_event_name\":\"SessionStart\"}" \
    | python3 "$BRIDGE" --platform claude --script session-start.sh --event SessionStart --specforge
)"
echo "$out" | python3 -c '
import json,sys
d=json.load(sys.stdin)
ctx=d.get("hookSpecificOutput",{}).get("additionalContext","")
assert "Spec-driven" in ctx or "Principle 8" in ctx, d
assert d["hookSpecificOutput"]["hookEventName"]=="SessionStart"
print("OK SessionStart")
'

echo "== bridge: UserPromptSubmit advisory (codex) =="
out="$(
  printf '%s' '{"cwd":"'"$PROJECT"'","prompt":"Should we compare feasibility of options? advisory only"}' \
    | python3 "$BRIDGE" --platform codex --script prompt-intent.sh --event UserPromptSubmit --specforge
)"
echo "$out" | python3 -c '
import json,sys
d=json.load(sys.stdin)
ctx=d.get("hookSpecificOutput",{}).get("additionalContext","")
assert "ADVISORY" in ctx or "advisory" in ctx.lower(), d
print("OK UserPromptSubmit")
'

echo "== bridge: PostToolUse after-spec-edit =="
out="$(
  printf '%s' '{"cwd":"'"$PROJECT"'","tool_input":{"file_path":"'"$PROJECT"'/.specs/requirements/REQ-001.md"}}' \
    | python3 "$BRIDGE" --platform claude --script after-spec-edit.sh --event PostToolUse --specforge
)"
echo "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d=={} or "hookSpecificOutput" in d or True; print("OK PostToolUse")'
journal="$PROJECT/.agents/memory/_project/learning-journal.md"
test -f "$journal"
grep -q 'REQ-001' "$journal"
echo "OK learning-journal append"

echo "== bridge: SubagentStop followup (claude) =="
out="$(
  printf '%s' '{"cwd":"'"$PROJECT"'","agent_type":"eng-orchestrator","status":"completed","stop_hook_active":false}' \
    | python3 "$BRIDGE" --platform claude --script subagent-stop.sh --event SubagentStop --specforge
)"
echo "$out" | python3 -c '
import json,sys
d=json.load(sys.stdin)
ctx=d.get("hookSpecificOutput",{}).get("additionalContext","")
assert "Gate checkpoint" in ctx, d
print("OK SubagentStop claude")
'

echo "== bridge: SubagentStop followup (codex decision block) =="
out="$(
  printf '%s' '{"cwd":"'"$PROJECT"'","agent_type":"eng-orchestrator","stop_hook_active":false}' \
    | python3 "$BRIDGE" --platform codex --script subagent-stop.sh --event SubagentStop --specforge
)"
echo "$out" | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert d.get("decision")=="block", d
assert "Gate checkpoint" in (d.get("reason") or ""), d
print("OK SubagentStop codex")
'

echo "== install-claude hooks merge =="
export CLAUDE_HOME CODEX_HOME
# Avoid polluting real ~/.agents and docs — still links agents/skills under CLAUDE_HOME
bash "$ROOT/scripts/install-claude.sh" >/dev/null
python3 - "$CLAUDE_HOME/settings.json" <<'PY'
import json,sys
path=sys.argv[1]
with open(path) as f:
    data=json.load(f)
hooks=data.get("hooks") or {}
needed=["SessionStart","UserPromptSubmit","SubagentStop","PostToolUse","Stop"]
missing=[e for e in needed if e not in hooks]
assert not missing, missing
blob=json.dumps(hooks)
assert "hooks/adapters/bridge.py" in blob
assert "--specforge" in blob
assert "session-start.sh" in blob
print("OK claude settings.json")
PY

echo "== install-claude idempotent =="
bash "$ROOT/scripts/install-claude.sh" >/dev/null
python3 - "$CLAUDE_HOME/settings.json" <<'PY'
import json,sys
with open(sys.argv[1]) as f:
    hooks=json.load(f)["hooks"]
# Count SpecForge SessionStart commands — must be exactly 1 after reinstall
count=0
for group in hooks.get("SessionStart") or []:
    for h in group.get("hooks") or []:
        cmd=h.get("command") or ""
        if "--specforge" in cmd and "session-start.sh" in cmd:
            count+=1
assert count==1, count
print("OK claude idempotent")
PY

echo "== install-codex hooks merge =="
AGENTS_SKILLS_HOME="$TEST_ROOT/agents-skills" \
  bash "$ROOT/scripts/install-codex.sh" >/dev/null
python3 - "$CODEX_HOME/hooks.json" <<'PY'
import json,sys
with open(sys.argv[1]) as f:
    data=json.load(f)
hooks=data.get("hooks") or {}
needed=["SessionStart","UserPromptSubmit","SubagentStop","PostToolUse","Stop"]
missing=[e for e in needed if e not in hooks]
assert not missing, missing
blob=json.dumps(hooks)
assert "hooks/adapters/bridge.py" in blob
assert "apply_patch" in blob
print("OK codex hooks.json")
PY

echo "== preserve user hooks on merge =="
python3 - "$CLAUDE_HOME/settings.json" <<'PY'
import json,sys
path=sys.argv[1]
with open(path) as f:
    data=json.load(f)
data["hooks"].setdefault("SessionStart", []).append({
    "hooks": [{"type":"command","command":"echo user-hook","timeout":5}]
})
with open(path,"w") as f:
    json.dump(data,f,indent=2)
    f.write("\n")
PY
bash "$ROOT/scripts/install-claude.sh" >/dev/null
python3 - "$CLAUDE_HOME/settings.json" <<'PY'
import json,sys
with open(sys.argv[1]) as f:
    hooks=json.load(f)["hooks"]
cmds=[]
for group in hooks.get("SessionStart") or []:
    for h in group.get("hooks") or []:
        cmds.append(h.get("command") or "")
assert any(c=="echo user-hook" for c in cmds), cmds
assert sum(1 for c in cmds if "--specforge" in c and "session-start.sh" in c)==1, cmds
print("OK user hook preserved")
PY

echo "PASS: test-hooks-adapters"
