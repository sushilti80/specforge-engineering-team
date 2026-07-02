#!/usr/bin/env python3
"""Detect advisory/docs/vendor intent and inject token discipline context."""
import json
import re
import sys

ADVISORY = re.compile(
    r"\b("
    r"critical\s+review|should\s+we|worth\s+it|compare|feasibility|"
    r"review\s+only|advisory|ask\s+mode|analyze\s+options|"
    r"can\s+we\s+(run|use|support)|help\s+us\s+decide|"
    r"what\s+do\s+you\s+think|pros\s+and\s+cons"
    r")\b",
    re.I,
)

IMPLEMENT = re.compile(
    r"\b(implement|apply\s+changes|build\s+it|create\s+pr|commit|go\s+ahead|"
    r"add\s+to\s+repo|make\s+the\s+changes|ship\s+it)\b",
    re.I,
)

DOCS = re.compile(
    r"\b(readme|roadmap|acknowledgment|docs/|documentation\s+only|"
    r"update\s+the\s+readme)\b",
    re.I,
)

VENDOR = re.compile(
    r"\b(sync-ponytail|vendor-sync|pull\s+ponytail|sync\s+upstream)\b",
    re.I,
)


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        print("{}")
        return

    prompt = data.get("prompt") or data.get("user_message") or data.get("text") or ""
    if not prompt.strip():
        print("{}")
        return

    lines: list[str] = []

    if VENDOR.search(prompt):
        lines.append(
            "## Token discipline: vendor-sync\n"
            "Recipe: `vendor-sync`. Run `bash scripts/sync-*.sh`; skill `spec-vendor-sync`. "
            "Do not paste upstream README into chat."
        )
    elif DOCS.search(prompt) and not IMPLEMENT.search(prompt):
        lines.append(
            "## Token discipline: docs-touch\n"
            "Profile: docs-touch (≤600 words). Edit only doc paths user named. "
            "No codebase exploration unless asked."
        )
    elif ADVISORY.search(prompt) and not IMPLEMENT.search(prompt):
        lines.append(
            "## Token discipline: ADVISORY mode\n"
            "Skills: `spec-advisory` + `spec-token-budget` (advisory profile). "
            "**Readonly** — no file edits unless user explicitly asks to implement. "
            "Verdict first (3 bullets). New chat for implementation after decision."
        )

    if not lines:
        print("{}")
        return

    print(json.dumps({"additional_context": "\n".join(lines)}))


if __name__ == "__main__":
    main()
