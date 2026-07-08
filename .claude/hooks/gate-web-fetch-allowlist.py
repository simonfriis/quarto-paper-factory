#!/usr/bin/env python3
"""Gate WebFetch to the project domain allowlist.

Fires as a PreToolUse hook matched to WebFetch. Allowlisted hosts (suffix-matched against
web-search-allowlist.json — so `stanford.edu` covers `web.stanford.edu`) are auto-allowed;
any off-list host prompts (`permissionDecision: "ask"`) so a full-page fetch from an unvetted
domain can't happen silently. WebFetch is the higher injection-risk tool — it pulls whole
pages into context — so this is the gate that matters most.

Off-list uses "ask" rather than "deny": the hook fires project-wide, and a hard deny would
block legitimate non-research fetches (e.g. doc lookups). To enforce strictly, set
OFF_LIST_DECISION = "deny".

Hook Event: PreToolUse (matcher "WebFetch").
"""

import json
import sys
from pathlib import Path
from urllib.parse import urlparse

ALLOWLIST_FILE = Path(__file__).resolve().parent / "web-search-allowlist.json"
OFF_LIST_DECISION = "ask"   # set to "deny" for strict enforcement


def load_allowlist() -> list[str]:
    """Read allowed_domains from the project allowlist file (lowercased)."""
    data = json.loads(ALLOWLIST_FILE.read_text())
    return [d.lower() for d in data.get("allowed_domains", []) if isinstance(d, str)]


def host_allowed(host: str, domains: list[str]) -> bool:
    """True if host equals, or is a subdomain of, any allowed domain."""
    host = host.lower().rstrip(".")
    return any(host == d or host.endswith("." + d) for d in domains)


def decide(decision: str, reason: str) -> None:
    """Emit a PreToolUse permission decision."""
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
            "permissionDecisionReason": reason,
        }
    }))


def main() -> int:
    """Allow allowlisted WebFetch hosts; ask for anything off-list."""
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        return 0
    if payload.get("tool_name") != "WebFetch":
        return 0

    url = (payload.get("tool_input") or {}).get("url", "")
    host = urlparse(url if "://" in url else f"https://{url}").hostname or ""

    try:
        domains = load_allowlist()
    except (json.JSONDecodeError, OSError):
        return 0   # allowlist unreadable -> defer to normal flow
    if not domains or not host:
        return 0

    if host_allowed(host, domains):
        decide("allow", f"{host} is on the project web allowlist")
    else:
        decide(OFF_LIST_DECISION,
               f"{host} is NOT on the project web allowlist "
               "(add it to web-search-allowlist.json if this is a trusted source)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
