#!/usr/bin/env python3
"""Inject the project WebSearch domain allowlist on every WebSearch call.

Fires as a PreToolUse hook matched to WebSearch. When the agent calls WebSearch
without an explicit `allowed_domains`, this hook injects the project-wide list
from web-search-allowlist.json -- so the curated scholarly allowlist applies to
every search without the agent re-specifying ~150 domains each call.

Behavior: inject-if-absent. An explicit per-call `allowed_domains` is respected
(lets a search narrow further); only an absent/empty one is filled in.

Hook Event: PreToolUse (matcher "WebSearch").
Output: hookSpecificOutput.updatedInput rewrites the tool input before it runs.

NOTE: input modification via PreToolUse is officially documented for
Bash/Edit/Write/MCP; WebSearch support is not documented, so this hook also
writes a debug line to LOG on every WebSearch call to make testing unambiguous.
"""

import json
import sys
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
ALLOWLIST_FILE = HERE / "web-search-allowlist.json"
LOG = HERE / ".web-search-hook.log"   # gitignored debug trace; remove once verified


def log(msg: str) -> None:
    """Append a timestamped debug line; never fail the hook on a logging error."""
    try:
        with open(LOG, "a") as f:
            f.write(f"{datetime.now().isoformat(timespec='seconds')}  {msg}\n")
    except OSError:
        pass


def load_allowlist() -> list[str]:
    """Read the allowed_domains array from the project allowlist file."""
    data = json.loads(ALLOWLIST_FILE.read_text())
    return [d for d in data.get("allowed_domains", []) if isinstance(d, str)]


def main() -> int:
    """Inject allowed_domains into a WebSearch call that lacks one."""
    # Read the hook payload; a malformed/empty stdin means "defer, change nothing".
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        return 0

    # Only act on WebSearch; everything else passes through untouched.
    if payload.get("tool_name") != "WebSearch":
        return 0

    tool_input = payload.get("tool_input") or {}
    query = tool_input.get("query", "")

    # Respect an explicit per-call allowlist -- only fill in an absent/empty one.
    if tool_input.get("allowed_domains"):
        log(f"SKIP (call already has allowed_domains)  query={query!r}")
        return 0

    # Load the project list; if the file is missing/broken, defer rather than block.
    try:
        domains = load_allowlist()
    except (json.JSONDecodeError, OSError) as e:
        log(f"DEFER (allowlist unreadable: {e})  query={query!r}")
        return 0
    if not domains:
        log(f"DEFER (allowlist empty)  query={query!r}")
        return 0

    # Inject and emit the rewritten tool input.
    updated = dict(tool_input)
    updated["allowed_domains"] = domains
    log(f"INJECT {len(domains)} domains  query={query!r}")

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": f"Applied WebSearch allowlist ({len(domains)} domains)",
            "updatedInput": updated,
        }
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
