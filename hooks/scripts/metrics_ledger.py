#!/usr/bin/env python3
"""Append spec-team activity to .agents/memory/_project/metrics/session.jsonl."""
from __future__ import annotations

import json
import os
from datetime import datetime, timezone


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
    "tech-lead",
}


def resolve_metrics_dir(cwd: str) -> str:
    for rel in (".agents/memory/_project/metrics", ".cursor/agent-memory/_project/metrics"):
        base = os.path.join(cwd, os.path.dirname(rel))
        if os.path.isdir(base) or rel.startswith(".agents"):
            path = os.path.join(cwd, rel)
            os.makedirs(path, exist_ok=True)
            return path
    path = os.path.join(cwd, ".agents", "memory", "_project", "metrics")
    os.makedirs(path, exist_ok=True)
    return path


def append_event(cwd: str, payload: dict) -> None:
    metrics_dir = resolve_metrics_dir(cwd)
    ledger = os.path.join(metrics_dir, "session.jsonl")
    payload.setdefault("ts", datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
    try:
        with open(ledger, "a", encoding="utf-8") as f:
            f.write(json.dumps(payload, separators=(",", ":")) + "\n")
    except OSError:
        pass


def log_subagent_complete(data: dict) -> None:
    if data.get("status") != "completed":
        return
    agent = data.get("subagent_type") or ""
    if agent not in SPEC_AGENTS:
        return
    cwd = data.get("cwd") or os.getcwd()
    modified = data.get("modified_files") or []
    spec_touch = any(
        ".specs/" in p or "agent-memory" in p or ".agents/memory/" in p for p in modified
    )
    append_event(
        cwd,
        {
            "event": "subagent_complete",
            "agent": agent,
            "files_modified": len(modified),
            "spec_touch": spec_touch,
            # Optional enrichment when caller/orchestrator provides them on the hook payload:
            **{
                k: data[k]
                for k in ("recipe", "tier", "phase", "round")
                if data.get(k) not in (None, "")
            },
        },
    )
