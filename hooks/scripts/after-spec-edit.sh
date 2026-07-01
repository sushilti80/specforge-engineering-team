#!/usr/bin/env python3
"""Append to learning-journal when .specs/ or agent-memory files are edited."""
import json
import os
import sys
from datetime import datetime, timezone


def resolve_journal_dir(cwd: str) -> str:
    for rel in (".agents/memory/_project", ".cursor/agent-memory/_project"):
        path = os.path.join(cwd, rel)
        if os.path.isdir(os.path.dirname(path)) or rel.startswith(".agents"):
            os.makedirs(path, exist_ok=True)
            return path
    fallback = os.path.join(cwd, ".agents", "memory", "_project")
    os.makedirs(fallback, exist_ok=True)
    return fallback


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        print("{}")
        return

    file_path = data.get("file_path") or data.get("path") or ""
    if not file_path:
        print("{}")
        return

    normalized = file_path.replace("\\", "/")
    is_spec = "/.specs/" in normalized or normalized.startswith(".specs/")
    is_memory = "agent-memory" in normalized or "/.agents/memory/" in normalized
    if not is_spec and not is_memory:
        print("{}")
        return

    cwd = data.get("cwd") or os.getcwd()
    journal_dir = resolve_journal_dir(cwd)
    journal = os.path.join(journal_dir, "learning-journal.md")

    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    kind = "spec" if is_spec else "memory"
    line = f"- {ts} [{kind}] `{file_path}` — review and distill into MEMORY.md if durable\n"

    try:
        with open(journal, "a", encoding="utf-8") as f:
            if os.path.getsize(journal) == 0:
                f.write("# Learning journal (append-only)\n\nAuto-logged by SpecForge plugin hooks.\nDistill durable facts into MEMORY.md; specs remain source of truth.\n\n")
            f.write(line)
    except OSError:
        pass

    print("{}")


if __name__ == "__main__":
    main()
