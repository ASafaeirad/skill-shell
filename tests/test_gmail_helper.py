from __future__ import annotations

import base64
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
    message_fetches: dict[str, int] = {}
    message_label_ids = ["INBOX", "UNREAD", "CATEGORY_PRIMARY", "Label_1"]
    history_changes: list[dict] = []
    history_id = "100"
    history_expired = False
    mutations: list[tuple[str, str, dict]] = []
    read_payload: dict | None = None

    def send_json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self) -> None:  # noqa: N802 - BaseHTTPRequestHandler API
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length).decode()
        if self.path.startswith("/gmail/v1/users/me/messages/"):
            payload = json.loads(body) if body else {}
            self.mutations.append((self.path, self.headers.get("Authorization", ""), payload))
            self.send_json(200, {"id": self.path.split("/")[6], "labelIds": ["INBOX"]})
            return
        form = urllib.parse.parse_qs(body)
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
        if self.path == "/gmail/v1/users/me/profile":
            self.send_json(200, {"historyId": self.history_id})
            return
        if self.path.startswith("/gmail/v1/users/me/history?"):
            if self.history_expired:
                self.send_json(404, {"error": {"status": "NOT_FOUND"}})
                return
            self.send_json(200, {"historyId": self.history_id, "history": self.history_changes})
            return
        if self.path.startswith("/gmail/v1/users/me/messages?labelIds=INBOX"):
            prefix = "personal" if "personal" in authorization else "work"
            self.send_json(200, {"messages": [{"id": f"{prefix}-1"}], "resultSizeEstimate": 2})
            return
        if self.path == "/gmail/v1/users/me/labels":
            self.send_json(200, {"labels": [
                {"id": "Label_1", "name": "Projects", "type": "user"},
                {"id": "Label_2", "name": "Personal", "type": "user"},
            ]})
            return
        if self.path.startswith("/gmail/v1/users/me/messages/"):
            message_id = self.path.split("/")[-1].split("?")[0]
            if self.path.endswith("?format=minimal"):
                self.send_json(200, {"id": message_id, "labelIds": self.message_label_ids})
                return
            self.message_fetches[message_id] = self.message_fetches.get(message_id, 0) + 1
            if self.read_payload is not None:
                self.send_json(200, self.read_payload)
                return
            self.send_json(200, {
                "id": message_id,
                "threadId": f"thread-{message_id}",
                "snippet": "A short preview",
                "internalDate": "1700000000000",
                "labelIds": self.message_label_ids,
                "payload": {
                    "headers": [{"name": "From", "value": "Alice <alice@example.com>"},
                                {"name": "Subject", "value": "Hello"}],
                    "parts": [{"filename": "report.pdf"}],
                },
            })
            return
        self.send_json(200, {"messagesUnread": counts[authorization]})

    def log_message(self, _format: str, *_args: object) -> None:
        return


class GmailHelperContractTest(unittest.TestCase):
    def setUp(self) -> None:
        GmailFixtureHandler.message_fetches = {}
        GmailFixtureHandler.message_label_ids = ["INBOX", "UNREAD", "CATEGORY_PRIMARY", "Label_1"]
        GmailFixtureHandler.history_changes = []
        GmailFixtureHandler.history_id = "100"
        GmailFixtureHandler.history_expired = False
        GmailFixtureHandler.mutations = []
        GmailFixtureHandler.read_payload = None
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

    def run_action(self, operation: str, **extra: object):
        return subprocess.run(
            [sys.executable, str(HELPER), "action"],
            input=json.dumps({
                "clientId": "desktop-client", "clientSecret": "secret-on-stdin",
                "refreshToken": "personal-token", "operation": operation,
                "messageId": "personal-1", **extra,
            }),
            text=True, capture_output=True, env=self.environment, check=False,
        )

    def run_read(self):
        return subprocess.run(
            [sys.executable, str(HELPER), "read"],
            input=json.dumps({
                "clientId": "desktop-client", "clientSecret": "secret-on-stdin",
                "refreshToken": "personal-token", "messageId": "personal-1",
            }),
            text=True, capture_output=True, env=self.environment, check=False,
        )

    def test_read_prefers_plain_text_and_lists_attachments_without_mutation(self) -> None:
        encode = lambda value: base64.urlsafe_b64encode(value.encode()).decode().rstrip("=")
        GmailFixtureHandler.read_payload = {
            "id": "personal-1", "threadId": "thread-personal-1",
            "internalDate": "1700000000000", "labelIds": ["INBOX", "UNREAD"],
            "payload": {
                "headers": [
                    {"name": "From", "value": "Alice <alice@example.com>"},
                    {"name": "To", "value": "Me <personal@example.com>"},
                    {"name": "Subject", "value": "Viewing"},
                ],
                "parts": [
                    {"mimeType": "text/html", "body": {"data": encode("<p>HTML fallback</p>")}},
                    {"mimeType": "text/plain", "body": {"data": encode("Plain message")}},
                    {"filename": "draft.pdf", "body": {"size": 253952, "attachmentId": "att-1"}},
                ],
            },
        }
        result = self.run_read()
        self.assertEqual(result.returncode, 0, result.stderr)
        detail = json.loads(result.stdout)
        self.assertEqual(detail["body"], "Plain message")
        self.assertEqual(detail["attachments"], [{"filename": "draft.pdf", "size": 253952}])
        self.assertEqual(detail["recipient"], "Me <personal@example.com>")
        self.assertEqual(detail["sender"], "Alice")
        self.assertEqual(GmailFixtureHandler.mutations, [])
        self.assertEqual(GmailFixtureHandler.read_payload["labelIds"], ["INBOX", "UNREAD"])

    def test_read_flattens_html_only_message(self) -> None:
        html = "<style>.x{display:none}</style><p>Hello &amp; welcome</p><div>Second line</div>"
        html += "<script>ignored()</script>"
        GmailFixtureHandler.read_payload = {
            "id": "personal-1", "internalDate": "1700000000000",
            "payload": {"mimeType": "text/html", "body": {
                "data": base64.urlsafe_b64encode(html.encode()).decode().rstrip("=")
            }},
        }
        result = self.run_read()
        self.assertEqual(result.returncode, 0, result.stderr)
        detail = json.loads(result.stdout)
        self.assertEqual(detail["body"], "Hello & welcome\nSecond line")
        self.assertEqual(detail["attachments"], [])

    def test_message_actions_use_modify_scope_operations(self) -> None:
        cases = [
            ("archive", {"removeLabelIds": ["INBOX"]}, "modify"),
            ("read", {"removeLabelIds": ["UNREAD"]}, "modify"),
            ("unread", {"addLabelIds": ["UNREAD"]}, "modify"),
            ("label", {"addLabelIds": ["Label_2"]}, "modify"),
            ("trash", {}, "trash"),
        ]
        for operation, expected_body, endpoint in cases:
            with self.subTest(operation=operation):
                result = self.run_action(operation, labelId="Label_2")
                self.assertEqual(result.returncode, 0, result.stdout)
                self.assertEqual(GmailFixtureHandler.mutations[-1], (
                    f"/gmail/v1/users/me/messages/personal-1/{endpoint}",
                    "Bearer access-personal-token", expected_body,
                ))

    def test_labels_action_lists_user_labels(self) -> None:
        result = self.run_action("labels")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(json.loads(result.stdout)["labels"], [
            {"id": "Label_2", "name": "Personal"},
            {"id": "Label_1", "name": "Projects"},
        ])

    def test_login_uses_loopback_pkce_and_returns_account(self) -> None:
        environment = {
            **self.environment,
            "GMAIL_AUTHORIZATION_URL": "https://accounts.example.test/authorize",
            "BROWSER": f"{sys.executable} {OAUTH_BROWSER} %s &",
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
        accounts = json.loads(result.stdout)["accounts"]
        self.assertEqual([account["unread"] for account in accounts], [4, 12])
        self.assertEqual([account["total"] for account in accounts], [2, 2])
        self.assertEqual(accounts[0]["messages"][0], {
            "id": "personal-1", "threadId": "thread-personal-1",
            "sender": "Alice", "subject": "Hello",
            "snippet": "A short preview", "timestamp": 1700000000000,
            "labelIds": ["INBOX", "UNREAD", "CATEGORY_PRIMARY", "Label_1"],
            "read": False, "attachment": True, "category": "Primary",
            "labels": ["Projects"],
        })

        cached = self.run_sync({
            "clientId": "desktop-client", "clientSecret": "secret-on-stdin",
            "accounts": [{"id": "personal", "email": "personal@example.com",
                          "refreshToken": "personal-token",
                          "knownMessages": accounts[0]["messages"],
                          "historyId": accounts[0]["historyId"]}],
        })
        self.assertEqual(cached.returncode, 0, cached.stderr)
        self.assertEqual(json.loads(cached.stdout)["accounts"][0]["messages"], accounts[0]["messages"])
        self.assertEqual(GmailFixtureHandler.message_fetches["personal-1"], 1)

    def test_sync_updates_cached_labels_from_history_without_refetching_details(self) -> None:
        account = {"id": "personal", "email": "personal@example.com", "refreshToken": "personal-token"}
        first = self.run_sync({
            "clientId": "desktop-client", "clientSecret": "secret-on-stdin", "accounts": [account],
        })
        self.assertEqual(first.returncode, 0, first.stderr)
        cached = json.loads(first.stdout)["accounts"][0]
        GmailFixtureHandler.history_id = "101"
        GmailFixtureHandler.history_changes = [{
            "labelsRemoved": [{"message": {"id": "personal-1"},
                               "labelIds": ["UNREAD", "CATEGORY_PRIMARY", "Label_1"]}],
            "labelsAdded": [{"message": {"id": "personal-1"},
                             "labelIds": ["CATEGORY_SOCIAL", "Label_2"]}],
        }]
        second = self.run_sync({
            "clientId": "desktop-client", "clientSecret": "secret-on-stdin",
            "accounts": [{**account, "knownMessages": cached["messages"],
                          "historyId": cached["historyId"]}],
        })
        self.assertEqual(second.returncode, 0, second.stderr)
        refreshed = json.loads(second.stdout)["accounts"][0]["messages"][0]
        self.assertTrue(refreshed["read"])
        self.assertEqual(refreshed["category"], "Social")
        self.assertEqual(refreshed["labels"], ["Personal"])
        self.assertEqual(GmailFixtureHandler.message_fetches["personal-1"], 1)

    def test_expired_history_fetches_only_current_labels(self) -> None:
        account = {"id": "personal", "email": "personal@example.com", "refreshToken": "personal-token"}
        first = self.run_sync({
            "clientId": "desktop-client", "clientSecret": "secret-on-stdin", "accounts": [account],
        })
        self.assertEqual(first.returncode, 0, first.stderr)
        cached = json.loads(first.stdout)["accounts"][0]
        GmailFixtureHandler.history_expired = True
        GmailFixtureHandler.message_label_ids = ["INBOX", "CATEGORY_PRIMARY", "Label_2"]
        second = self.run_sync({
            "clientId": "desktop-client", "clientSecret": "secret-on-stdin",
            "accounts": [{**account, "knownMessages": cached["messages"],
                          "historyId": cached["historyId"]}],
        })
        self.assertEqual(second.returncode, 0, second.stderr)
        refreshed = json.loads(second.stdout)["accounts"][0]["messages"][0]
        self.assertTrue(refreshed["read"])
        self.assertEqual(refreshed["labels"], ["Personal"])
        self.assertEqual(GmailFixtureHandler.message_fetches["personal-1"], 1)

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

    def test_mixed_results_report_failure_and_keep_successful_counts(self) -> None:
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
                        "refreshToken": "expired-token",
                    },
                ],
            }
        )

        self.assertEqual(result.returncode, 2)
        accounts = json.loads(result.stdout)["accounts"]
        self.assertEqual(accounts[0]["unread"], 4)
        self.assertEqual(accounts[1]["error"], "expired")

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
