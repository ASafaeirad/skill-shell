#!/usr/bin/python3
"""Gmail OAuth and unread-count helper.

The process contract is JSON on stdin and JSON on stdout. Secrets must never be
passed as command-line arguments.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
from email.utils import parseaddr
import http.client
import json
import os
import secrets
import sys
import time
import urllib.parse
import webbrowser
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Any


EXIT_SUCCESS = 0
EXIT_EXPIRED = 2
EXIT_NETWORK = 3

AUTHORIZATION_URL = os.environ.get(
    "GMAIL_AUTHORIZATION_URL", "https://accounts.google.com/o/oauth2/v2/auth"
)
TOKEN_URL = os.environ.get("GMAIL_TOKEN_URL", "https://oauth2.googleapis.com/token")
API_BASE_URL = os.environ.get(
    "GMAIL_API_BASE_URL", "https://gmail.googleapis.com/gmail/v1"
).rstrip("/")
GMAIL_READONLY_SCOPE = "https://www.googleapis.com/auth/gmail.readonly"


class GmailError(Exception):
    outcome = "network"


class AuthorizationExpired(GmailError):
    outcome = "expired"


class NetworkUnavailable(GmailError):
    outcome = "network"


class HistoryExpired(GmailError):
    """Gmail no longer retains changes since the previous sync."""


class JsonHttpClient:
    """Small JSON client that reuses one connection per origin."""

    def __init__(self, timeout: float = 20) -> None:
        self.timeout = timeout
        self._connections: dict[tuple[str, str, int | None], http.client.HTTPConnection] = {}

    def close(self) -> None:
        for connection in self._connections.values():
            connection.close()
        self._connections.clear()

    def request(
        self,
        method: str,
        url: str,
        *,
        headers: dict[str, str] | None = None,
        form: dict[str, str] | None = None,
    ) -> dict[str, Any]:
        parsed = urllib.parse.urlsplit(url)
        port = parsed.port
        key = (parsed.scheme, parsed.hostname or "", port)
        connection = self._connections.get(key)
        if connection is None:
            connection_type = (
                http.client.HTTPSConnection
                if parsed.scheme == "https"
                else http.client.HTTPConnection
            )
            connection = connection_type(parsed.hostname, port, timeout=self.timeout)
            self._connections[key] = connection

        body: bytes | None = None
        request_headers = dict(headers or {})
        if form is not None:
            body = urllib.parse.urlencode(form).encode("utf-8")
            request_headers["Content-Type"] = "application/x-www-form-urlencoded"
        path = urllib.parse.urlunsplit(("", "", parsed.path or "/", parsed.query, ""))

        try:
            connection.request(method, path, body=body, headers=request_headers)
            response = connection.getresponse()
            payload = response.read()
        except (OSError, http.client.HTTPException) as error:
            connection.close()
            self._connections.pop(key, None)
            raise NetworkUnavailable(str(error)) from error

        try:
            decoded = json.loads(payload.decode("utf-8")) if payload else {}
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise NetworkUnavailable("Gmail returned an invalid response") from error

        if response.status >= 400:
            reason = decoded.get("error")
            if isinstance(reason, dict):
                reason = reason.get("status") or reason.get("message")
            if response.status == 401 or reason == "invalid_grant":
                raise AuthorizationExpired(str(reason or "authorisation expired"))
            if response.status == 404 and parsed.path.endswith("/history"):
                raise HistoryExpired(str(reason or "history expired"))
            raise NetworkUnavailable(str(reason or f"HTTP {response.status}"))
        return decoded


def read_request() -> dict[str, Any]:
    try:
        request = json.load(sys.stdin)
    except json.JSONDecodeError as error:
        raise ValueError("stdin must contain one JSON object") from error
    if not isinstance(request, dict):
        raise ValueError("stdin must contain one JSON object")
    return request


def write_response(payload: dict[str, Any]) -> None:
    json.dump(payload, sys.stdout, separators=(",", ":"))
    sys.stdout.write("\n")


def require_string(request: dict[str, Any], key: str) -> str:
    value = request.get(key)
    if not isinstance(value, str) or not value:
        raise ValueError(f"{key} is required")
    return value


def exchange_refresh_token(
    client: JsonHttpClient, client_id: str, client_secret: str, refresh_token: str
) -> str:
    response = client.request(
        "POST",
        TOKEN_URL,
        form={
            "client_id": client_id,
            "client_secret": client_secret,
            "refresh_token": refresh_token,
            "grant_type": "refresh_token",
        },
    )
    access_token = response.get("access_token")
    if not isinstance(access_token, str) or not access_token:
        raise AuthorizationExpired("token response did not include an access token")
    return access_token


def gmail_get(client: JsonHttpClient, path: str, access_token: str) -> dict[str, Any]:
    return client.request(
        "GET",
        f"{API_BASE_URL}{path}",
        headers={"Authorization": f"Bearer {access_token}"},
    )


def stable_account_id(email: str) -> str:
    return hashlib.sha256(email.strip().lower().encode("utf-8")).hexdigest()[:16]


def has_attachment(part: dict[str, Any]) -> bool:
    if part.get("filename"):
        return True
    return any(has_attachment(child) for child in part.get("parts", []) if isinstance(child, dict))


def label_fields(label_ids: list[str], labels: dict[str, str]) -> dict[str, Any]:
    return {
        "read": "UNREAD" not in label_ids,
        "category": next((labels.get(label, label.removeprefix("CATEGORY_").title())
                          for label in label_ids if label.startswith("CATEGORY_")), ""),
        "labels": [labels[label] for label in label_ids if label in labels and not label.startswith("CATEGORY_")],
    }


def normalize_message(message: dict[str, Any], labels: dict[str, str]) -> dict[str, Any]:
    headers = {
        str(header.get("name", "")).lower(): str(header.get("value", ""))
        for header in message.get("payload", {}).get("headers", [])
        if isinstance(header, dict)
    }
    sender_name, sender_address = parseaddr(headers.get("from", ""))
    label_ids = message.get("labelIds", [])
    return {
        "id": message["id"],
        "threadId": message.get("threadId", message["id"]),
        "sender": sender_name or sender_address or "Unknown sender",
        "subject": headers.get("subject", "(no subject)"),
        "snippet": message.get("snippet", ""),
        "timestamp": int(message.get("internalDate", 0)),
        "labelIds": label_ids,
        "attachment": has_attachment(message.get("payload", {})),
        **label_fields(label_ids, labels),
    }


def update_known_labels(
    client: JsonHttpClient, access_token: str, history_id: str,
    known: dict[str, dict[str, Any]],
) -> set[str]:
    changed: set[str] = set()
    page_token = ""
    while True:
        query = {"startHistoryId": history_id}
        if page_token:
            query["pageToken"] = page_token
        path = f"/users/me/history?{urllib.parse.urlencode(query)}"
        response = gmail_get(client, path, access_token)
        for record in response.get("history", []):
            for field, adding in (("labelsAdded", True), ("labelsRemoved", False)):
                for change in record.get(field, []):
                    message_id = change.get("message", {}).get("id")
                    if message_id not in known:
                        continue
                    label_ids = set(known[message_id].get("labelIds", []))
                    if adding:
                        label_ids.update(change.get("labelIds", []))
                    else:
                        label_ids.difference_update(change.get("labelIds", []))
                    known[message_id]["labelIds"] = sorted(label_ids)
                    changed.add(message_id)
        page_token = response.get("nextPageToken", "")
        if not page_token:
            return changed


def reload_known_labels(
    client: JsonHttpClient, access_token: str, known: dict[str, dict[str, Any]],
) -> set[str]:
    for message_id, message in known.items():
        minimal = gmail_get(
            client,
            f"/users/me/messages/{urllib.parse.quote(message_id)}?format=minimal",
            access_token,
        )
        message["labelIds"] = minimal.get("labelIds", [])
    return set(known)


class OAuthCallbackHandler(BaseHTTPRequestHandler):
    server: "OAuthCallbackServer"

    def do_GET(self) -> None:  # noqa: N802 - BaseHTTPRequestHandler API
        query = urllib.parse.parse_qs(urllib.parse.urlsplit(self.path).query)
        self.server.callback = {key: values[0] for key, values in query.items()}
        body = b"Gmail sign-in complete. You can close this tab."
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, _format: str, *_args: object) -> None:
        return


class OAuthCallbackServer(HTTPServer):
    callback: dict[str, str] | None = None


def wait_for_oauth_callback(server: OAuthCallbackServer, timeout: float) -> dict[str, str]:
    deadline = time.monotonic() + timeout
    server.timeout = min(1.0, timeout)
    while server.callback is None and time.monotonic() < deadline:
        server.handle_request()
    if server.callback is None:
        raise NetworkUnavailable("timed out waiting for Google sign-in")
    return server.callback


def login(request: dict[str, Any]) -> tuple[dict[str, Any], int]:
    client_id = require_string(request, "clientId")
    client_secret = require_string(request, "clientSecret")
    verifier = base64.urlsafe_b64encode(secrets.token_bytes(48)).rstrip(b"=").decode("ascii")
    challenge = base64.urlsafe_b64encode(
        hashlib.sha256(verifier.encode("ascii")).digest()
    ).rstrip(b"=").decode("ascii")
    state = secrets.token_urlsafe(24)

    with OAuthCallbackServer(("127.0.0.1", 0), OAuthCallbackHandler) as server:
        redirect_uri = f"http://127.0.0.1:{server.server_port}/oauth/callback"
        parameters = {
            "client_id": client_id,
            "redirect_uri": redirect_uri,
            "response_type": "code",
            "scope": GMAIL_READONLY_SCOPE,
            "access_type": "offline",
            "prompt": "consent",
            "code_challenge": challenge,
            "code_challenge_method": "S256",
            "state": state,
        }
        authorization_url = f"{AUTHORIZATION_URL}?{urllib.parse.urlencode(parameters)}"
        if not webbrowser.open(authorization_url):
            raise NetworkUnavailable("could not open the system browser")
        callback = wait_for_oauth_callback(server, float(request.get("timeoutSeconds", 300)))

    if callback.get("state") != state:
        raise AuthorizationExpired("OAuth state did not match")
    if callback.get("error"):
        raise AuthorizationExpired(callback["error"])
    code = callback.get("code")
    if not code:
        raise AuthorizationExpired("Google did not return an authorisation code")

    client = JsonHttpClient()
    try:
        token_response = client.request(
            "POST",
            TOKEN_URL,
            form={
                "client_id": client_id,
                "client_secret": client_secret,
                "code": code,
                "code_verifier": verifier,
                "grant_type": "authorization_code",
                "redirect_uri": redirect_uri,
            },
        )
        refresh_token = token_response.get("refresh_token")
        access_token = token_response.get("access_token")
        if not isinstance(refresh_token, str) or not refresh_token:
            raise AuthorizationExpired("Google did not return a refresh token")
        if not isinstance(access_token, str) or not access_token:
            raise AuthorizationExpired("Google did not return an access token")
        profile = gmail_get(client, "/users/me/profile", access_token)
    finally:
        client.close()

    email = profile.get("emailAddress")
    if not isinstance(email, str) or not email:
        raise AuthorizationExpired("Gmail profile did not include an email address")
    return {
        "account": {
            "id": stable_account_id(email),
            "email": email,
            "refreshToken": refresh_token,
        }
    }, EXIT_SUCCESS


def sync(request: dict[str, Any]) -> tuple[dict[str, Any], int]:
    client_id = require_string(request, "clientId")
    client_secret = require_string(request, "clientSecret")
    raw_accounts = request.get("accounts", [])
    if not isinstance(raw_accounts, list):
        raise ValueError("accounts must be a list")

    results: list[dict[str, Any]] = []
    outcomes: list[str] = []
    client = JsonHttpClient()
    try:
        for account in raw_accounts:
            if not isinstance(account, dict):
                continue
            account_id = str(account.get("id", ""))
            email = str(account.get("email", ""))
            result: dict[str, Any] = {
                "id": account_id,
                "email": email,
                "unread": None,
                "messages": account.get("knownMessages", []),
                "historyId": account.get("historyId", ""),
                "total": 0,
                "error": None,
            }
            try:
                try:
                    refresh_token = require_string(account, "refreshToken")
                except ValueError as error:
                    raise AuthorizationExpired("refresh token is missing") from error
                access_token = exchange_refresh_token(
                    client, client_id, client_secret, refresh_token
                )
                profile = gmail_get(client, "/users/me/profile", access_token)
                unread_label = gmail_get(client, "/users/me/labels/UNREAD", access_token)
                result["unread"] = int(unread_label.get("messagesUnread", 0))
                inbox = gmail_get(client, "/users/me/messages?labelIds=INBOX&maxResults=12", access_token)
                listed = inbox.get("messages", [])
                result["total"] = int(inbox.get("resultSizeEstimate", len(listed)))
                listed_ids = {item["id"] for item in listed if isinstance(item.get("id"), str)}
                known = {
                    item["id"]: dict(item) for item in account.get("knownMessages", [])
                    if isinstance(item, dict) and item.get("id") in listed_ids
                }
                new_ids = [item["id"] for item in listed if item.get("id") not in known]
                changed_ids: set[str] = set()
                if known and account.get("historyId"):
                    try:
                        changed_ids = update_known_labels(
                            client, access_token, str(account["historyId"]), known
                        )
                    except HistoryExpired:
                        changed_ids = reload_known_labels(client, access_token, known)
                elif known:
                    changed_ids = reload_known_labels(client, access_token, known)
                labels: dict[str, str] = {}
                if new_ids or changed_ids:
                    label_response = gmail_get(client, "/users/me/labels", access_token)
                    labels = {
                        label["id"]: label.get("name", label["id"])
                        for label in label_response.get("labels", [])
                        if label.get("type") == "user" or label.get("id", "").startswith("CATEGORY_")
                    }
                for message_id in changed_ids:
                    known[message_id].update(label_fields(known[message_id]["labelIds"], labels))
                messages = []
                for item in listed:
                    message_id = item["id"]
                    if message_id in known:
                        messages.append(known[message_id])
                    else:
                        detail = gmail_get(client, f"/users/me/messages/{urllib.parse.quote(message_id)}?format=full", access_token)
                        messages.append(normalize_message(detail, labels))
                result["messages"] = messages
                result["historyId"] = str(profile.get("historyId", ""))
                outcomes.append("success")
            except GmailError as error:
                result["error"] = error.outcome
                outcomes.append(error.outcome)
            results.append(result)
    finally:
        client.close()

    exit_code = EXIT_SUCCESS
    if "expired" in outcomes:
        exit_code = EXIT_EXPIRED
    elif "network" in outcomes:
        exit_code = EXIT_NETWORK
    return {"accounts": results}, exit_code


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("login", "sync"))
    args = parser.parse_args()
    try:
        request = read_request()
        payload, exit_code = login(request) if args.command == "login" else sync(request)
    except AuthorizationExpired as error:
        payload, exit_code = {"error": error.outcome}, EXIT_EXPIRED
    except (NetworkUnavailable, OSError):
        payload, exit_code = {"error": "network"}, EXIT_NETWORK
    except (TypeError, ValueError, KeyError) as error:
        payload, exit_code = {"error": "invalid_request", "message": str(error)}, 1
    write_response(payload)
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
