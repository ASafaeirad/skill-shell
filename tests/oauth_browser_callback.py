from __future__ import annotations

import sys
import urllib.parse
import urllib.request


MODIFY_SCOPE = "https://www.googleapis.com/auth/gmail.modify"


def main() -> int:
    authorization_url = sys.argv[1]
    query = urllib.parse.parse_qs(urllib.parse.urlsplit(authorization_url).query)
    if query.get("scope") != [MODIFY_SCOPE]:
        return 1
    if query.get("code_challenge_method") != ["S256"]:
        return 1
    callback = query["redirect_uri"][0]
    callback_query = urllib.parse.urlencode(
        {"code": "fixture-code", "state": query["state"][0]}
    )
    with urllib.request.urlopen(f"{callback}?{callback_query}", timeout=2) as response:
        response.read()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
