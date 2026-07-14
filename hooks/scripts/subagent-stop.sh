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
    "platform-engineer",
    "sre-devops",
    "debugger",
    "data-engineer",
    "mobile-engineer",
    "adr-recorder",
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

    agent = data.get("subagent_type") or data.get("agent_type") or ""
    if agent not in SPEC_AGENTS:
        print("{}")
        return

    # Ensure agent key is set for ledger helpers that only look at subagent_type.
    data["subagent_type"] = agent
    modified = log_subagent_complete(data)
    spec_touch = any(
        ".specs/" in p.replace("\\", "/")
        or "agent-memory" in p.replace("\\", "/")
        or "/.agents/memory/" in p.replace("\\", "/")
        for p in modified
    )

    msg = (
        f"Gate checkpoint (Principle 8): subagent `{agent}` completed. "
        "Before the next gate: (1) update `.specs/` if needed, "
        "(2) update `.agents/memory/_project/specs-index.md`, "
        "(3) update orchestrator MEMORY.md, "
        "(4) optionally write `.specs/handoffs/GATE-*.md`. "
        "Then delegate with the spawn allowlist (paths only) — fresh subagent. "
        "Do not attach a chat summary, HANDOFF prose, or tool logs to the next spawn."
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
