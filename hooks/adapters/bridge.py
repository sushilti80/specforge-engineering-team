#!/usr/bin/env python3
"""Bridge Cursor-shaped SpecForge hooks to Claude Code / Codex CLI / Copilot I/O.

Usage:
  bridge.py --platform claude|codex|copilot --script <name> [--event <HookEventName>]

Reads platform JSON on stdin, normalizes to Cursor contract, runs
hooks/scripts/<name>.sh, translates stdout back to the platform shape.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from typing import Any

SCRIPT_TO_EVENT = {
    "session-start.sh": "SessionStart",
    "prompt-intent.sh": "UserPromptSubmit",
    "subagent-stop.sh": "SubagentStop",
    "after-spec-edit.sh": "PostToolUse",
    "session-stop.sh": "Stop",
}

# Copilot uses camelCase event names and reads `toolName`, `agentName`, `prompt`.
COPILOT_EVENT_ALIASES = {
    "sessionStart": "SessionStart",
    "userPromptSubmitted": "UserPromptSubmit",
    "postToolUse": "PostToolUse",
    "subagentStop": "SubagentStop",
    "agentStop": "Stop",
}

ADAPTER_DIR = os.path.dirname(os.path.abspath(__file__))
PLUGIN_ROOT = os.path.dirname(os.path.dirname(ADAPTER_DIR))
SCRIPTS_DIR = os.path.join(PLUGIN_ROOT, "hooks", "scripts")
# Cloud-vendored layout: scripts/specforge-hooks/bridge.py + scripts/specforge-hooks/scripts/
VENDORED_SCRIPTS_DIR = os.path.join(ADAPTER_DIR, "scripts")
if not os.path.isdir(SCRIPTS_DIR) and os.path.isdir(VENDORED_SCRIPTS_DIR):
    SCRIPTS_DIR = VENDORED_SCRIPTS_DIR


def _extract_file_path(data: dict[str, Any]) -> str:
    if data.get("file_path"):
        return str(data["file_path"])
    if data.get("path"):
        return str(data["path"])

    tool_input = data.get("tool_input")
    if isinstance(tool_input, dict):
        for key in ("file_path", "path", "filePath", "file"):
            if tool_input.get(key):
                return str(tool_input[key])
        # apply_patch / patch payloads sometimes nest paths
        for key in ("path", "file_path"):
            for nested_key in ("change", "edit", "update"):
                nested = tool_input.get(nested_key)
                if isinstance(nested, dict) and nested.get(key):
                    return str(nested[key])
        command = tool_input.get("command")
        if isinstance(command, str):
            # Best-effort: first path-like token mentioning .specs or memory
            for token in command.replace("***", " ").split():
                if "/.specs/" in token or ".specs/" in token or "/.agents/memory/" in token:
                    return token.strip("'\"")

    tool_response = data.get("tool_response")
    if isinstance(tool_response, dict):
        for key in ("file_path", "path"):
            if tool_response.get(key):
                return str(tool_response[key])

    return ""


def normalize_stdin(data: dict[str, Any]) -> dict[str, Any]:
    """Map Claude/Codex/Copilot stdin fields onto the Cursor hook contract."""
    out = dict(data)

    cwd = data.get("cwd") or os.getcwd()
    out["cwd"] = cwd

    prompt = (
        data.get("prompt")
        or data.get("user_message")
        or data.get("text")
        or ""
    )
    out["prompt"] = prompt

    file_path = _extract_file_path(data)
    if file_path:
        out["file_path"] = file_path

    agent = (
        data.get("subagent_type")
        or data.get("agent_type")
        or data.get("agent_id")
        or data.get("agentName")
        or ""
    )
    if agent:
        out["subagent_type"] = str(agent)

    if "status" not in out:
        # Claude/Codex/Copilot SubagentStop fires when the subagent finished.
        out["status"] = "completed"

    if "loop_count" not in out:
        if data.get("stop_hook_active") is True:
            out["loop_count"] = 1
        else:
            out["loop_count"] = 0

    if "modified_files" not in out or not out.get("modified_files"):
        # Prefer explicit lists; also accept alternate key names from platforms.
        candidates = []
        for key in (
            "modified_files",
            "files_modified",
            "changed_files",
            "edited_files",
            "file_changes",
        ):
            val = data.get(key)
            if isinstance(val, list) and val:
                candidates = val
                break
            if isinstance(val, str) and val.strip():
                candidates = [val.strip()]
                break
        out["modified_files"] = candidates

    return out


def translate_stdout(
    platform: str,
    event_name: str,
    cursor_out: dict[str, Any],
) -> dict[str, Any]:
    """Map Cursor hook JSON to Claude/Codex/Copilot stdout."""
    if not cursor_out:
        return {}

    additional = cursor_out.get("additional_context")
    followup = cursor_out.get("followup_message")

    if platform == "copilot":
        # Copilot: flat `additionalContext` (string) at top level;
        # only the main agent stopping (agentStop/Stop) can force another turn
        # via decision:block. subagentStop nudges the orchestrator with context.
        if additional:
            return {"additionalContext": additional}
        if followup and event_name in ("agentStop", "Stop"):
            return {"decision": "block", "reason": followup}
        if followup:
            return {"additionalContext": followup}
        return {}

    if additional:
        return {
            "hookSpecificOutput": {
                "hookEventName": event_name,
                "additionalContext": additional,
            }
        }

    if followup:
        if platform == "codex" and event_name in ("Stop", "SubagentStop"):
            # Codex continues the turn/subagent when decision=block + reason.
            return {
                "decision": "block",
                "reason": followup,
                "systemMessage": followup,
            }
        # Claude Stop/SubagentStop: additionalContext continues the conversation.
        return {
            "hookSpecificOutput": {
                "hookEventName": event_name,
                "additionalContext": followup,
            }
        }

    return {}


def run_core_script(script_name: str, normalized: dict[str, Any]) -> dict[str, Any]:
    script_path = os.path.join(SCRIPTS_DIR, script_name)
    if not os.path.isfile(script_path):
        return {}

    env = os.environ.copy()
    env["SPECFORGE_HOOK_BRIDGE"] = "1"
    proc = subprocess.run(
        [sys.executable, script_path],
        input=json.dumps(normalized),
        capture_output=True,
        text=True,
        env=env,
        cwd=normalized.get("cwd") or os.getcwd(),
        check=False,
    )
    raw = (proc.stdout or "").strip()
    if not raw:
        return {}
    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError:
        return {}
    return parsed if isinstance(parsed, dict) else {}


def main() -> int:
    parser = argparse.ArgumentParser(description="SpecForge Claude/Codex/Copilot hook bridge")
    parser.add_argument("--platform", choices=("claude", "codex", "copilot"), required=True)
    parser.add_argument(
        "--script",
        required=True,
        help="Core script basename, e.g. session-start.sh",
    )
    parser.add_argument(
        "--event",
        default="",
        help="Hook event name override (default derived from --script)",
    )
    parser.add_argument(
        "--specforge",
        action="store_true",
        help="Marker so installers can identify SpecForge-owned hook entries",
    )
    args = parser.parse_args()

    script_name = args.script
    if not script_name.endswith(".sh"):
        script_name = f"{script_name}.sh"

    event_name = args.event or SCRIPT_TO_EVENT.get(script_name, "SessionStart")
    # Normalize Copilot camelCase event names to the canonical forms used internally.
    event_name = COPILOT_EVENT_ALIASES.get(event_name, event_name)

    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        print("{}")
        return 0

    if not isinstance(data, dict):
        print("{}")
        return 0

    normalized = normalize_stdin(data)
    cursor_out = run_core_script(script_name, normalized)
    platform_out = translate_stdout(args.platform, event_name, cursor_out)
    print(json.dumps(platform_out if platform_out else {}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
