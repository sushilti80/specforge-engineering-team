#!/usr/bin/env python3
"""Append spec-team activity to .agents/memory/_project/metrics/session.jsonl.

Cursor's subagentStop often sends empty `modified_files` even when the
subagent wrote files. We therefore:

1. Prefer hook-provided modified_files (and common aliases).
2. Fall back to claiming recent paths recorded by afterFileEdit into edits.jsonl.
3. Optionally sample paths from agent_transcript_path when present.
"""
from __future__ import annotations

import json
import os
import re
from datetime import datetime, timezone
from typing import Any, Iterable


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

WRITE_TOOL_NAMES = {
    "Write",
    "StrReplace",
    "EditNotebook",
    "Delete",
    "ApplyPatch",
    "search_replace",
    "write",
    "edit_notebook",
    "delete_file",
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


def _now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _as_path_list(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, str):
        value = value.strip()
        if not value:
            return []
        if value.startswith("["):
            try:
                parsed = json.loads(value)
            except json.JSONDecodeError:
                return [value]
            return _as_path_list(parsed)
        return [value]
    if isinstance(value, (list, tuple, set)):
        out: list[str] = []
        for item in value:
            if isinstance(item, str) and item.strip():
                out.append(item.strip())
            elif isinstance(item, dict):
                for key in ("path", "file_path", "filePath", "file"):
                    p = item.get(key)
                    if isinstance(p, str) and p.strip():
                        out.append(p.strip())
                        break
        return out
    return []


def extract_modified_files(data: dict) -> list[str]:
    """Collect modified paths from common hook payload shapes."""
    keys = (
        "modified_files",
        "files_modified",
        "changed_files",
        "edited_files",
        "file_changes",
        "files",
    )
    found: list[str] = []
    for key in keys:
        found.extend(_as_path_list(data.get(key)))
    # de-dupe preserving order
    seen: set[str] = set()
    out: list[str] = []
    for p in found:
        if p not in seen:
            seen.add(p)
            out.append(p)
    return out


def record_file_edit(cwd: str, file_path: str, data: dict | None = None) -> None:
    """Record an afterFileEdit path for later claim on subagentStop."""
    if not file_path:
        return
    data = data or {}
    metrics_dir = resolve_metrics_dir(cwd)
    edits_path = os.path.join(metrics_dir, "edits.jsonl")
    payload = {
        "event": "file_edit",
        "ts": _now_iso(),
        "path": file_path,
        "claimed": False,
    }
    for key in ("conversation_id", "generation_id", "session_id", "agent_id", "subagent_type"):
        val = data.get(key)
        if val not in (None, ""):
            payload[key] = val
    try:
        with open(edits_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(payload, separators=(",", ":")) + "\n")
    except OSError:
        pass


def _parse_ts(s: str) -> datetime | None:
    if not s:
        return None
    raw = s.strip()
    if raw.endswith("Z"):
        raw = raw[:-1] + "+00:00"
    try:
        dt = datetime.fromisoformat(raw)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def claim_pending_edits(
    cwd: str,
    data: dict,
    *,
    max_age_seconds: int | None = None,
) -> list[str]:
    """Claim unclaimed afterFileEdit paths for this subagent completion.

    Prefer matching conversation_id / generation_id when present; otherwise
    claim all still-unclaimed edits (best-effort for sequential pipelines).
    """
    metrics_dir = resolve_metrics_dir(cwd)
    edits_path = os.path.join(metrics_dir, "edits.jsonl")
    if not os.path.isfile(edits_path):
        return []

    conv = data.get("conversation_id") or ""
    gen = data.get("generation_id") or ""
    duration_ms = data.get("duration_ms")
    if max_age_seconds is None:
        if isinstance(duration_ms, (int, float)) and duration_ms > 0:
            # Small grace window beyond reported duration.
            max_age_seconds = int(duration_ms / 1000) + 120
        else:
            max_age_seconds = 2 * 60 * 60  # 2h safety net

    now = datetime.now(timezone.utc)
    try:
        with open(edits_path, encoding="utf-8") as f:
            lines = f.readlines()
    except OSError:
        return []

    claimed_paths: list[str] = []
    rewritten: list[str] = []
    for line in lines:
        raw = line.strip()
        if not raw:
            continue
        try:
            row = json.loads(raw)
        except json.JSONDecodeError:
            rewritten.append(line if line.endswith("\n") else line + "\n")
            continue

        if row.get("event") != "file_edit" or row.get("claimed"):
            rewritten.append(json.dumps(row, separators=(",", ":")) + "\n")
            continue

        path = row.get("path") or ""
        if not path:
            rewritten.append(json.dumps(row, separators=(",", ":")) + "\n")
            continue

        row_conv = row.get("conversation_id") or ""
        row_gen = row.get("generation_id") or ""
        matched = True
        if conv and row_conv and row_conv != conv:
            matched = False
        if gen and row_gen and row_gen != gen:
            matched = False

        ts = _parse_ts(str(row.get("ts") or ""))
        if matched and ts is not None:
            age = (now - ts).total_seconds()
            if age < 0:
                age = 0
            if age > max_age_seconds:
                matched = False

        if matched:
            row["claimed"] = True
            row["claimed_by"] = data.get("subagent_type") or data.get("agent_type") or ""
            row["claimed_ts"] = _now_iso()
            claimed_paths.append(path)

        rewritten.append(json.dumps(row, separators=(",", ":")) + "\n")

    try:
        with open(edits_path, "w", encoding="utf-8") as f:
            f.writelines(rewritten)
    except OSError:
        return claimed_paths

    # de-dupe preserving order
    seen: set[str] = set()
    out: list[str] = []
    for p in claimed_paths:
        if p not in seen:
            seen.add(p)
            out.append(p)
    return out


def _walk_paths_from_obj(obj: Any, out: set[str], tools: set[str]) -> None:
    if isinstance(obj, dict):
        name = obj.get("name") or obj.get("toolName") or obj.get("tool") or ""
        if isinstance(name, str) and name in WRITE_TOOL_NAMES:
            tools.add(name)
            for key in ("path", "file_path", "filePath", "target_notebook"):
                val = obj.get(key)
                if isinstance(val, str) and val.strip():
                    out.add(val.strip())
            args = obj.get("arguments") or obj.get("input") or obj.get("params")
            if isinstance(args, str):
                try:
                    args = json.loads(args)
                except json.JSONDecodeError:
                    args = None
            if isinstance(args, dict):
                for key in ("path", "file_path", "filePath", "target_notebook"):
                    val = args.get(key)
                    if isinstance(val, str) and val.strip():
                        out.add(val.strip())
        for val in obj.values():
            _walk_paths_from_obj(val, out, tools)
    elif isinstance(obj, list):
        for item in obj:
            _walk_paths_from_obj(item, out, tools)


def extract_files_from_transcript(path: str) -> list[str]:
    """Best-effort parse of agent_transcript_path for write-tool file paths."""
    if not path or not os.path.isfile(path):
        return []
    found: set[str] = set()
    tools: set[str] = set()
    try:
        with open(path, encoding="utf-8", errors="ignore") as f:
            for i, line in enumerate(f):
                if i > 20000:
                    break
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    # Loose path scrape for non-JSON transcript formats
                    for m in re.finditer(
                        r'"(?:path|file_path|filePath)"\s*:\s*"([^"]+)"', line
                    ):
                        found.add(m.group(1))
                    continue
                _walk_paths_from_obj(obj, found, tools)
    except OSError:
        return []
    return sorted(found)


def resolve_modified_files(cwd: str, data: dict) -> tuple[list[str], str]:
    """Return (paths, source) where source is hook|edits_buffer|transcript|none."""
    hook_files = extract_modified_files(data)
    if hook_files:
        return hook_files, "hook"

    claimed = claim_pending_edits(cwd, data)
    if claimed:
        return claimed, "edits_buffer"

    transcript = (
        data.get("agent_transcript_path")
        or data.get("transcript_path")
        or ""
    )
    if isinstance(transcript, str) and transcript:
        tx_files = extract_files_from_transcript(transcript)
        if tx_files:
            return tx_files, "transcript"

    return [], "none"


def _rel_sample(cwd: str, paths: Iterable[str], limit: int = 12) -> list[str]:
    sample: list[str] = []
    cwd_abs = os.path.abspath(cwd)
    for p in paths:
        if len(sample) >= limit:
            break
        try:
            abs_p = os.path.abspath(p)
            if abs_p.startswith(cwd_abs + os.sep):
                sample.append(os.path.relpath(abs_p, cwd_abs))
            else:
                sample.append(p)
        except OSError:
            sample.append(p)
    return sample


def log_subagent_complete(data: dict) -> list[str]:
    """Append ledger event; return resolved modified file paths."""
    if data.get("status") != "completed":
        return []
    agent = data.get("subagent_type") or data.get("agent_type") or ""
    if agent not in SPEC_AGENTS:
        return []
    cwd = data.get("cwd") or os.getcwd()
    modified, source = resolve_modified_files(cwd, data)
    spec_touch = any(
        ".specs/" in p.replace("\\", "/")
        or "agent-memory" in p.replace("\\", "/")
        or "/.agents/memory/" in p.replace("\\", "/")
        or p.replace("\\", "/").startswith(".agents/memory/")
        for p in modified
    )
    event = {
        "event": "subagent_complete",
        "agent": agent,
        "files_modified": len(modified),
        "files_source": source,
        "spec_touch": spec_touch,
        **{
            k: data[k]
            for k in ("recipe", "tier", "phase", "round")
            if data.get(k) not in (None, "")
        },
    }
    if modified:
        event["files_sample"] = _rel_sample(cwd, modified)
    append_event(cwd, event)
    return modified
