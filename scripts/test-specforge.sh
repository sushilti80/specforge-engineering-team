#!/usr/bin/env bash
# TP-004 smoke tests for specforge CLI (isolated store).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$ROOT/tmp/sf-test-automated"
STORE="$TEST_ROOT/store"
PROJECT="$TEST_ROOT/project"
export SPECFORGE_HOME_DIR="$STORE"

rm -rf "$TEST_ROOT"
mkdir -p "$PROJECT"

echo "== install-local =="
bash "$ROOT/scripts/specforge.sh" install-local

echo "== init =="
bash "$ROOT/scripts/specforge.sh" init "$PROJECT" --platform cursor,claude

echo "== doctor =="
( cd "$PROJECT" && bash "$ROOT/scripts/specforge.sh" doctor )

echo "== status =="
( cd "$PROJECT" && bash "$ROOT/scripts/specforge.sh" status )

echo "== versions =="
bash "$ROOT/scripts/specforge.sh" versions

echo "PASS: TP-004 smoke"
