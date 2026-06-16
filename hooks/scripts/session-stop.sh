#!/usr/bin/env python3
"""Gentle end-of-session reminder to update agent memory after spec work."""
import json
import os
import sys
from datetime import datetime, timezone, timedelta


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        print("{}")
        return

    if int(data.get("loop_count") or 0) > 0:
        print("{}")
        return

    cwd = data.get("cwd") or os.getcwd()
    journal = os.path.join(cwd, ".cursor", "agent-memory", "_project", "learning-journal.md")
    if not os.path.isfile(journal):
        print("{}")
        return

    try:
        mtime = datetime.fromtimestamp(os.path.getmtime(journal), tz=timezone.utc)
    except OSError:
        print("{}")
        return

    if datetime.now(timezone.utc) - mtime > timedelta(minutes=30):
        print("{}")
        return

    msg = (
        "Session ending after recent spec/memory edits. "
        "Distill learning-journal entries into `.cursor/agent-memory/*/MEMORY.md` "
        "and update `specs-index.md`. Then start a fresh chat for the next gate if context is stale."
    )
    print(json.dumps({"followup_message": msg}))


if __name__ == "__main__":
    main()
