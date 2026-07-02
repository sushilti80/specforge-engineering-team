#!/usr/bin/env python3
"""Distill learning-journal tail into _project/MEMORY.md (P3 token hygiene)."""
from __future__ import annotations

import argparse
import os
import re
from datetime import datetime, timezone


def resolve_paths(cwd: str) -> tuple[str, str]:
    for rel in (".agents/memory/_project", ".cursor/agent-memory/_project"):
        base = os.path.join(cwd, rel)
        if os.path.isdir(base):
            return (
                os.path.join(base, "learning-journal.md"),
                os.path.join(base, "MEMORY.md"),
            )
    base = os.path.join(cwd, ".agents", "memory", "_project")
    return (
        os.path.join(base, "learning-journal.md"),
        os.path.join(base, "MEMORY.md"),
    )


def extract_bullets(journal_text: str, max_entries: int = 20) -> list[str]:
    bullets: list[str] = []
    for line in journal_text.splitlines():
        line = line.strip()
        if not line.startswith("- "):
            continue
        # Skip header noise
        if "Auto-logged" in line or line.startswith("- ---"):
            continue
        bullets.append(line[2:].strip())
    return bullets[-max_entries:]


def main() -> None:
    parser = argparse.ArgumentParser(description="Distill learning journal into MEMORY.md")
    parser.add_argument("--project", default=".", help="Project root")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--max", type=int, default=8, help="Max journal lines to distill")
    args = parser.parse_args()

    cwd = os.path.abspath(args.project)
    journal_path, memory_path = resolve_paths(cwd)

    if not os.path.isfile(journal_path):
        print(f"No journal: {journal_path}")
        return

    with open(journal_path, encoding="utf-8") as f:
        journal = f.read()

    entries = extract_bullets(journal, max_entries=args.max * 3)
    if not entries:
        print("Journal empty — nothing to distill.")
        return

    # Dedupe by file path in backticks
    seen: set[str] = set()
    unique: list[str] = []
    for e in reversed(entries):
        m = re.search(r"`([^`]+)`", e)
        key = m.group(1) if m else e[:60]
        if key in seen:
            continue
        seen.add(key)
        unique.append(e)
        if len(unique) >= args.max:
            break
    unique.reverse()

    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    block = (
        f"\n\n## Distilled from learning journal ({ts})\n"
        + "\n".join(f"- {u}" for u in unique)
        + "\n"
    )

    if args.dry_run:
        print(block)
        return

    os.makedirs(os.path.dirname(memory_path), exist_ok=True)
    existing = ""
    if os.path.isfile(memory_path):
        with open(memory_path, encoding="utf-8") as f:
            existing = f.read()

    marker = "## Distilled from learning journal"
    if marker in existing:
        head = existing.split(marker)[0].rstrip()
        new_content = head + block
    else:
        new_content = existing.rstrip() + block

    # Keep MEMORY.md under ~200 lines (playbook guidance)
    lines = new_content.splitlines()
    if len(lines) > 200:
        new_content = "\n".join(lines[:200]) + "\n\n<!-- truncated by distill-journal.sh -->\n"

    with open(memory_path, "w", encoding="utf-8") as f:
        f.write(new_content if new_content.endswith("\n") else new_content + "\n")

    print(f"Distilled {len(unique)} entries → {memory_path}")


if __name__ == "__main__":
    main()
