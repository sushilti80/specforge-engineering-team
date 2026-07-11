#!/usr/bin/env python3
"""Remind orchestrator to checkpoint after spec-team subagents complete."""
import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from metrics_ledger import log_subagent_complete  # noqa: E402

SPEC_AGENTS = {
    "requirements-analyst",
    "architect",
    "challenger",
    "adr-recorder",
    "spec-guardian",
    "verifier",
    "eng-orchestrator",
    "qa-engineer",
    "backend-engineer",
    "frontend-engineer",
    "fullstack-engineer",
    "code-reviewer",
    "security-reviewer",
    "test-runner",
}


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        print("{}")
        return

    if data.get("status") != "completed":
        print("{}")
        return

    if int(data.get("loop_count") or 0) > 0:
        print("{}")
        return

    agent = data.get("subagent_type") or ""
    if agent not in SPEC_AGENTS:
        print("{}")
        return

    log_subagent_complete(data)

    modified = data.get("modified_files") or []
    spec_touch = any(
        ".specs/" in p or "agent-memory" in p or ".agents/memory/" in p for p in modified
    )

    msg = (
        f"Gate checkpoint (Principle 8): subagent `{agent}` completed. "
        "Before the next gate: (1) update `.specs/` if needed, "
        "(2) update `.agents/memory/_project/specs-index.md`, "
        "(3) update orchestrator MEMORY.md, "
        "(4) optionally write `.specs/handoffs/GATE-*.md`. "
        "Then delegate to the next agent with spec paths only — fresh subagent, no prose paste."
    )
    if spec_touch:
        msg += " Spec or memory files were modified — confirm learning-journal and HANDOFF memory paths."

    msg += (
        " Token: if HANDOFF or last response is long, compress to ≤500 words paths-only "
        "(skill spec-token-budget, profile handoff) before delegating."
    )

    print(json.dumps({"followup_message": msg}))


if __name__ == "__main__":
    main()
