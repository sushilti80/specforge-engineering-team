#!/usr/bin/env bash
# Tests for the ForgeCode SpecForge adapter (agent `id:` compat + symlink install + bootstrap).
# ForgeCode has no user-configurable hooks (PR #2757 closed), so no bridge tests here.
# Usage: bash scripts/test-forge-adapter.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$ROOT/tmp/sf-forge-test"
FORGE_HOME="$TEST_ROOT/forge"
AGENTS_SKILLS_HOME="$TEST_ROOT/agents-skills"
BOOTSTRAP_PROJECT="$TEST_ROOT/bootstrap-project"

rm -rf "$TEST_ROOT"
mkdir -p "$FORGE_HOME"

# ---------------------------------------------------------------------------
# Source agents: every agent file must carry `id:` (ForgeCode requires it)
# ---------------------------------------------------------------------------
echo "== source agents carry id: =="
python3 - "$ROOT/agents" <<'PY'
import json, os, sys, re
agents_dir = sys.argv[1]
files = sorted(f for f in os.listdir(agents_dir) if f.endswith(".md"))
assert len(files) == 20, f"expected 20 agents, found {len(files)}: {files}"
missing_id = []
mismatched = []
for f in files:
    path = os.path.join(agents_dir, f)
    with open(path) as fh:
        content = fh.read()
    # frontmatter is between first pair of ---
    if not content.startswith("---"):
        missing_id.append(f); continue
    end = content.index("---", 3)
    fm = content[3:end]
    name_m = re.search(r'^name:\s*(\S+)', fm, re.M)
    id_m = re.search(r'^id:\s*(\S+)', fm, re.M)
    if not id_m:
        missing_id.append(f); continue
    if name_m and id_m.group(1) != name_m.group(1):
        mismatched.append((f, name_m.group(1), id_m.group(1)))
assert not missing_id, f"agents missing id: {missing_id}"
assert not mismatched, f"agents where id != name: {mismatched}"
print(f"OK all 20 agents carry id: matching name:")
PY

# ---------------------------------------------------------------------------
# install-forge.sh: symlink agents → ~/forge/agents/*.md (plain .md, no rename)
# ---------------------------------------------------------------------------
echo "== install-forge symlinks agents =="
export FORGE_HOME AGENTS_SKILLS_HOME
bash "$ROOT/scripts/install-forge.sh" >/dev/null

python3 - "$FORGE_HOME/agents" <<'PY'
import os, sys, re
agents_dir = sys.argv[1]
files = [f for f in os.listdir(agents_dir) if f.endswith(".md")]
assert len(files) == 20, f"expected 20 symlinked agents, found {len(files)}"
# Each must be a symlink
for f in files:
    p = os.path.join(agents_dir, f)
    assert os.path.islink(p), f"{f} is not a symlink"
# ForgeCode reads `id:` — verify it survived the symlink (symlink points at source)
target = os.path.join(agents_dir, "eng-orchestrator.md")
with open(target) as fh:
    fm = fh.read().split("---")[1]
assert re.search(r'^id:\s*eng-orchestrator', fm, re.M), "eng-orchestrator missing id:"
print("OK 20 agents symlinked to ~/forge/agents/*.md with id:")
PY

echo "== install-forge places AGENTS.md + docs =="
test -f "$FORGE_HOME/AGENTS.md"
test -d "$FORGE_HOME/specforge"
test -d "$AGENTS_SKILLS_HOME/spec-pipeline"
echo "OK AGENTS.md + specforge docs + skills linked"

echo "== install-forge idempotent =="
bash "$ROOT/scripts/install-forge.sh" >/dev/null
count=$(ls "$FORGE_HOME/agents"/*.md 2>/dev/null | wc -l | tr -d ' ')
[[ "$count" == "20" ]] || { echo "FAIL: expected 20 agents after reinstall, got $count"; exit 1; }
echo "OK idempotent (still 20 agents)"

# ---------------------------------------------------------------------------
# bootstrap --platform forge: project-local .forge/agents (symlinks)
# ---------------------------------------------------------------------------
echo "== bootstrap --platform forge =="
rm -rf "$BOOTSTRAP_PROJECT"
mkdir -p "$BOOTSTRAP_PROJECT"
bash "$ROOT/scripts/bootstrap-project.sh" --platform forge "$BOOTSTRAP_PROJECT" >/dev/null

python3 - "$BOOTSTRAP_PROJECT" <<'PY'
import os, sys, re
proj = sys.argv[1]
# .forge/agents exists with 20 symlinks
agents_dir = os.path.join(proj, ".forge", "agents")
assert os.path.isdir(agents_dir), ".forge/agents missing"
files = [f for f in os.listdir(agents_dir) if f.endswith(".md")]
assert len(files) == 20, f"expected 20 bootstrapped agents, found {len(files)}"
# .forge/commands exists (linked from plugin commands)
cmds = os.path.join(proj, ".forge", "commands")
assert os.path.isdir(cmds), ".forge/commands missing"
# .agents/skills exists (cross-tool skills)
skills = os.path.join(proj, ".agents", "skills")
assert os.path.isdir(skills), ".agents/skills missing"
# .specs + .agents/memory + AGENTS.md created by bootstrap core
assert os.path.isdir(os.path.join(proj, ".specs"))
assert os.path.isfile(os.path.join(proj, "AGENTS.md"))
assert os.path.isdir(os.path.join(proj, ".agents", "memory"))
# No .github copilot vendoring leaked in (platform=forge only)
assert not os.path.exists(os.path.join(proj, ".github", "hooks", "specforge.json")), "copilot hooks leaked into forge bootstrap"
# No hooks dir for forge (no hooks support)
assert not os.path.exists(os.path.join(proj, ".forge", "hooks")), "unexpected .forge/hooks (forge has no hooks)"
print("OK bootstrap --platform forge: .forge/agents + .forge/commands + .agents/skills, no hooks")
PY

echo "PASS: test-forge-adapter"
