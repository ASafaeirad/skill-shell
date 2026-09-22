from __future__ import annotations

import json
import os
import socket
import subprocess
import sys
import threading
import unittest
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


HELPER = Path(__file__).parents[1] / "scripts" / "gmail" / "gmail_helper.py"
OAUTH_BROWSER = Path(__file__).with_name("oauth_browser_callback.py")


class GmailFixtureHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def send_json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self) -> None:  # noqa: N802 - BaseHTTPRequestHandler API
        length = int(self.headers.get("Content-Length", "0"))
        form = urllib.parse.parse_qs(self.rfile.read(length).decode())
        refresh_token = form.get("refresh_token", [""])[0]
        if form.get("grant_type") == ["authorization_code"]:
            self.send_json(
                200,
                {"access_token": "login-access-token", "refresh_token": "login-refresh-token"},
            )
            return
        if refresh_token == "expired-token":
            self.send_json(400, {"error": "invalid_grant"})
            return
        self.send_json(200, {"access_token": f"access-{refresh_token}"})

    def do_GET(self) -> None:  # noqa: N802 - BaseHTTPRequestHandler API
        authorization = self.headers.get("Authorization", "")
        if self.path == "/gmail/v1/users/me/profile" and authorization == "Bearer login-access-token":
            self.send_json(200, {"emailAddress": "person@example.com"})
            return
        counts = {"Bearer access-personal-token": 4, "Bearer access-work-token": 12}
        if authorization not in counts:
            self.send_json(401, {"error": {"status": "UNAUTHENTICATED"}})
            return
        self.send_json(200, {"messagesUnread": counts[authorization]})

    def log_message(self, _format: str, *_args: object) -> None:
        return


class GmailHelperContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), GmailFixtureHandler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        origin = f"http://127.0.0.1:{self.server.server_port}"
        self.environment = {
            **os.environ,
            "GMAIL_TOKEN_URL": f"{origin}/token",
            "GMAIL_API_BASE_URL": f"{origin}/gmail/v1",
        }

    def tearDown(self) -> None:
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()

    def run_sync(self, request: dict, environment: dict[str, str] | None = None):
        return subprocess.run(
            [sys.executable, str(HELPER), "sync"],
            input=json.dumps(request),
            text=True,
            capture_output=True,
            env=environment or self.environment,
            check=False,
        )

    def test_login_uses_loopback_pkce_and_returns_account(self) -> None:
        environment = {
            **self.environment,
            "GMAIL_AUTHORIZATION_URL": "https://accounts.example.test/authorize",
            "BROWSER": f"{sys.executable} {OAUTH_BROWSER} %s",
        }
        result = subprocess.run(
            [sys.executable, str(HELPER), "login"],
            input=json.dumps(
                {
                    "clientId": "desktop-client",
                    "clientSecret": "secret-on-stdin",
                    "timeoutSeconds": 3,
                }
            ),
            text=True,
            capture_output=True,
            env=environment,
            check=False,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        account = json.loads(result.stdout)["account"]
        self.assertEqual(account["email"], "person@example.com")
        self.assertEqual(account["refreshToken"], "login-refresh-token")
        self.assertEqual(len(account["id"]), 16)

    def test_sync_normalizes_multiple_unread_counts(self) -> None:
        result = self.run_sync(
            {
                "clientId": "desktop-client",
                "clientSecret": "secret-on-stdin",
                "accounts": [
                    {
                        "id": "personal",
                        "email": "personal@example.com",
                        "refreshToken": "personal-token",
                    },
                    {
                        "id": "work",
                        "email": "work@example.com",
                        "refreshToken": "work-token",
                    },
                ],
            }
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            json.loads(result.stdout),
            {
                "accounts": [
                    {
                        "id": "personal",
                        "email": "personal@example.com",
                        "unread": 4,
                        "error": None,
                    },
                    {
                        "id": "work",
                        "email": "work@example.com",
                        "unread": 12,
                        "error": None,
                    },
                ]
            },
        )

    def test_expired_authorisation_has_distinct_exit_code(self) -> None:
        result = self.run_sync(
            {
                "clientId": "desktop-client",
                "clientSecret": "secret-on-stdin",
                "accounts": [
                    {
                        "id": "personal",
                        "email": "personal@example.com",
                        "refreshToken": "expired-token",
                    }
                ],
            }
        )

        self.assertEqual(result.returncode, 2)
        self.assertEqual(json.loads(result.stdout)["accounts"][0]["error"], "expired")

    def test_unreachable_network_has_distinct_exit_code(self) -> None:
        with socket.socket() as probe:
            probe.bind(("127.0.0.1", 0))
            unused_port = probe.getsockname()[1]
        environment = {
            **os.environ,
            "GMAIL_TOKEN_URL": f"http://127.0.0.1:{unused_port}/token",
            "GMAIL_API_BASE_URL": f"http://127.0.0.1:{unused_port}/gmail/v1",
        }
        result = self.run_sync(
            {
                "clientId": "desktop-client",
                "clientSecret": "secret-on-stdin",
                "accounts": [
                    {
                        "id": "personal",
                        "email": "personal@example.com",
                        "refreshToken": "personal-token",
                    }
                ],
            },
            environment,
        )

        self.assertEqual(result.returncode, 3)
        self.assertEqual(json.loads(result.stdout)["accounts"][0]["error"], "network")


if __name__ == "__main__":
    unittest.main()
