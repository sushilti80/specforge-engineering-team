#!/usr/bin/env python3
"""Inject spec-driven context when a project has .specs/ or agent-memory."""
import json
import os
import sys


def resolve_memory_project_dir(cwd: str) -> str | None:
    for rel in (".agents/memory/_project", ".cursor/agent-memory/_project"):
        path = os.path.join(cwd, rel)
        if os.path.isdir(path):
            return path
    return None


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        print("{}")
        return

    cwd = data.get("cwd") or os.getcwd()
    specs_dir = os.path.join(cwd, ".specs")
    memory_dir = resolve_memory_project_dir(cwd)
    has_specs = os.path.isdir(specs_dir)
    has_memory = memory_dir is not None

    if not has_specs and not has_memory:
        print("{}")
        return

    lines = [
        "## Spec-driven engineering team (plugin)",
        "",
        "Principle 8: ephemeral chat, durable specs. Read `.specs/` and `.agents/memory/` — not chat history.",
        "",
        "Paths:",
        f"- Specs: `{specs_dir}`" if has_specs else "- Specs: (not bootstrapped)",
        f"- Memory: `{memory_dir}`" if has_memory else "- Memory: (not bootstrapped)",
        "",
        "At gate boundaries: update specs-index.md, agent MEMORY.md, optional `.specs/handoffs/GATE-*.md`.",
        "Delegate with file paths only (≤500 words). Fresh subagent per gate.",
        "",
        "Token discipline: skills `spec-token-budget`, `spec-advisory` for review-only prompts. "
        "Verdict-first; no file edits on advisory unless user says implement.",
        "",
        "Playbook: `SPECFORGE_HOME/ENGINEERING-PLAYBOOK.md` (Cursor: `~/.cursor/ENGINEERING-PLAYBOOK.md`)",
        "Orchestrator: `/eng-orchestrator` · Pipeline: `/spec-pipeline`",
    ]

    journal = os.path.join(memory_dir, "learning-journal.md") if memory_dir else ""
    if journal and os.path.isfile(journal):
        try:
            with open(journal, encoding="utf-8") as f:
                tail = f.read().strip().splitlines()[-8:]
            if tail:
                lines.extend(["", "### Recent learning journal", *tail])
        except OSError:
            pass

    print(json.dumps({"additional_context": "\n".join(lines)}))


if __name__ == "__main__":
    main()
