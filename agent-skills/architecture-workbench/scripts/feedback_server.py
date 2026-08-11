#!/usr/bin/env python3
"""Serve the generated Workbench and store validated feedback on loopback only."""

from __future__ import annotations

import argparse
import ipaddress
import json
import secrets
import sys
from datetime import UTC, datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

from architecture_workbench import (
    ContractError,
    STABLE_ID,
    feedback_markdown,
    load_documents,
    normalize_feedback_payload,
    run_git,
    validate_documents,
)


MAX_BODY_BYTES = 64 * 1024
LOOPBACK_HOSTS = {"127.0.0.1", "localhost", "::1"}


def request_is_local(client_ip: str, host_header: str, origin: str | None, port: int) -> bool:
    try:
        if not ipaddress.ip_address(client_ip).is_loopback:
            return False
    except ValueError:
        return False

    try:
        parsed_host = urlparse(f"//{host_header}")
        host = (parsed_host.hostname or "").lower()
        host_port = parsed_host.port
    except ValueError:
        return False
    if host not in LOOPBACK_HOSTS or (host_port or 80) != port:
        return False
    if origin:
        parsed = urlparse(origin)
        if parsed.scheme != "http" or parsed.hostname not in LOOPBACK_HOSTS:
            return False
        if (parsed.port or 80) != port:
            return False
    return True


def feedback_file(
    root: Path,
    feedback_directory: Path,
    payload: Any,
    *,
    feedback_id: str,
    created_at: str,
) -> tuple[Path, dict[str, str]]:
    documents = load_documents(root, Path("docs/architecture-workbench/current"))
    validate_documents(root, documents)
    normalized = normalize_feedback_payload(payload, documents)
    if not STABLE_ID.fullmatch(feedback_id):
        raise ContractError("feedback ID must be a stable server-generated ID")
    commit = normalized["verifiedGitCommit"]
    if run_git(root, ["cat-file", "-e", f"{commit}^{{commit}}"], check=False).returncode != 0:
        raise ContractError(f"feedback verifiedGitCommit does not exist: {commit}")
    destination = (root / feedback_directory).resolve()
    repository = root.resolve()
    if destination != repository and repository not in destination.parents:
        raise ContractError("feedback directory must remain inside the repository")
    destination.mkdir(parents=True, exist_ok=True)
    path = destination / f"{feedback_id}.md"
    with path.open("x", encoding="utf-8", errors="strict") as stream:
        stream.write(feedback_markdown(normalized, feedback_id, created_at))
    return path, normalized


class FeedbackHandler(BaseHTTPRequestHandler):
    root = Path.cwd()
    site = Path("docs/architecture-workbench/site/index.html")
    feedback_directory = Path("docs/architecture-workbench/feedback/open")
    server_version = "ArchitectureWorkbenchFeedback/1"

    def setup(self) -> None:
        super().setup()
        self.connection.settimeout(5)

    def log_message(self, format: str, *args: object) -> None:
        print(f"feedback-server: {format % args}", file=sys.stderr)

    def send_json(self, status: int, payload: dict[str, Any]) -> None:
        body = (json.dumps(payload, ensure_ascii=False) + "\n").encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(body)

    def local_request(self) -> bool:
        return request_is_local(
            self.client_address[0],
            self.headers.get("Host", ""),
            self.headers.get("Origin"),
            self.server.server_port,
        )

    def do_GET(self) -> None:  # noqa: N802
        if not self.local_request():
            self.send_json(403, {"error": "loopback request required"})
            return
        if self.path == "/api/health":
            self.send_json(200, {"status": "ok", "writeScope": str(self.feedback_directory)})
            return
        if self.path not in {"/", "/index.html"}:
            self.send_json(404, {"error": "not found"})
            return
        path = self.root / self.site
        try:
            body = path.read_bytes()
        except OSError as error:
            self.send_json(500, {"error": str(error)})
            return
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Security-Policy", "default-src 'self'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; connect-src 'self'")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self) -> None:  # noqa: N802
        if self.path != "/api/feedback":
            self.send_json(404, {"error": "not found"})
            return
        if not self.local_request():
            self.send_json(403, {"error": "loopback request required"})
            return
        if self.headers.get_content_type() != "application/json":
            self.send_json(415, {"error": "application/json required"})
            return
        try:
            length = int(self.headers.get("Content-Length", ""))
        except ValueError:
            self.send_json(411, {"error": "valid Content-Length required"})
            return
        if length < 1 or length > MAX_BODY_BYTES:
            self.send_json(413, {"error": "feedback body must be 1 to 65536 bytes"})
            return
        try:
            payload = json.loads(self.rfile.read(length))
            now = datetime.now(UTC)
            feedback_id = f"feedback-{now:%Y%m%dt%H%M%S}-{secrets.token_hex(4)}"
            path, normalized = feedback_file(
                self.root,
                self.feedback_directory,
                payload,
                feedback_id=feedback_id,
                created_at=now.isoformat().replace("+00:00", "Z"),
            )
        except (ContractError, UnicodeDecodeError, json.JSONDecodeError, OSError) as error:
            self.send_json(400, {"error": str(error)})
            return
        self.send_json(
            201,
            {
                "feedbackId": feedback_id,
                "status": normalized["status"],
                "path": str(path.relative_to(self.root)),
            },
        )


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--root", type=Path, default=Path.cwd())
    result.add_argument("--port", type=int, default=8765)
    result.add_argument(
        "--feedback", type=Path, default=Path("docs/architecture-workbench/feedback/open")
    )
    return result


def main() -> int:
    options = parser().parse_args()
    root = options.root.resolve()
    if not 0 <= options.port <= 65535:
        print("port must be between 0 and 65535", file=sys.stderr)
        return 2

    class ConfiguredHandler(FeedbackHandler):
        pass

    ConfiguredHandler.root = root
    ConfiguredHandler.feedback_directory = options.feedback
    server = ThreadingHTTPServer(("127.0.0.1", options.port), ConfiguredHandler)
    print(f"http://127.0.0.1:{server.server_port}", file=sys.stderr)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
