import importlib.util
import io
import json
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace

from test_markdown_parser import RepositoryFixture, git, workbench


SERVER_SCRIPT = Path(__file__).parents[1] / "scripts" / "feedback_server.py"
SERVER_SPEC = importlib.util.spec_from_file_location("architecture_workbench_feedback_server", SERVER_SCRIPT)
server = importlib.util.module_from_spec(SERVER_SPEC)
assert SERVER_SPEC.loader is not None
sys.modules[SERVER_SPEC.name] = server
SERVER_SPEC.loader.exec_module(server)


class NonClosingBytesIO(io.BytesIO):
    def close(self) -> None:
        pass


class FakeSocket:
    def __init__(self, request: bytes) -> None:
        self.input = NonClosingBytesIO(request)
        self.output = NonClosingBytesIO()
        self.timeout = None

    def makefile(self, mode: str, buffering: int = -1) -> NonClosingBytesIO:
        return self.input if "r" in mode else self.output

    def sendall(self, data: bytes) -> None:
        self.output.write(data)

    def settimeout(self, timeout: int) -> None:
        self.timeout = timeout

    def shutdown(self, how: int) -> None:
        pass

    def close(self) -> None:
        pass


class FeedbackTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture = RepositoryFixture()
        self.fixture.write()
        self.documents = workbench.load_documents(
            self.fixture.root, Path("docs/architecture-workbench/current")
        )

    def tearDown(self) -> None:
        self.fixture.close()

    def payload(self, **overrides: str) -> dict[str, str]:
        result = {
            "targetId": "root",
            "targetDocumentId": "current.architecture",
            "verifiedGitCommit": self.fixture.commit,
            "category": "question",
            "request": "Who owns this boundary?",
            "context": "child depends-on root",
        }
        result.update(overrides)
        return result

    def http_response(
        self,
        method: str,
        path: str,
        *,
        body: bytes = b"",
        headers: dict[str, str] | None = None,
    ) -> tuple[bytes, int | None]:
        values = {"Host": "127.0.0.1:8765", **(headers or {})}
        raw_headers = "".join(f"{key}: {value}\r\n" for key, value in values.items())
        request = f"{method} {path} HTTP/1.1\r\n{raw_headers}\r\n".encode() + body
        socket = FakeSocket(request)

        class ConfiguredHandler(server.FeedbackHandler):
            root = self.fixture.root.resolve()
            feedback_directory = Path("docs/architecture-workbench/feedback/open")

            def log_message(self, format: str, *args: object) -> None:
                pass

        ConfiguredHandler(socket, ("127.0.0.1", 50000), SimpleNamespace(server_port=8765))
        return socket.output.getvalue(), socket.timeout

    def test_current_and_stale_request_status_uses_target_verified_commit(self) -> None:
        current = workbench.normalize_feedback_payload(self.payload(), self.documents)
        self.assertEqual(current["status"], "open")

        (self.fixture.root / "README.md").write_text("later\n", encoding="utf-8")
        git(self.fixture.root, "add", "README.md")
        git(self.fixture.root, "commit", "-qm", "later commit")
        later = git(self.fixture.root, "rev-parse", "HEAD")
        stale = workbench.normalize_feedback_payload(
            self.payload(verifiedGitCommit=later), self.documents
        )
        self.assertEqual(stale["status"], "needs-review")

    def test_payload_rejects_unknown_target_extra_field_and_oversized_request(self) -> None:
        with self.assertRaisesRegex(workbench.ContractError, "stable ID"):
            workbench.normalize_feedback_payload(self.payload(targetId="missing"), self.documents)
        extra = {**self.payload(), "path": "../../outside"}
        with self.assertRaisesRegex(workbench.ContractError, "unsupported fields"):
            workbench.normalize_feedback_payload(extra, self.documents)
        with self.assertRaisesRegex(workbench.ContractError, "1 to 4000"):
            workbench.normalize_feedback_payload(self.payload(request="x" * 4001), self.documents)

    def test_trace_feedback_targets_require_unique_stable_ids(self) -> None:
        invalid = self.fixture.valid_body().replace("## trace.fixture", "## Trace Not Stable")
        self.fixture.write(body=invalid)
        with self.assertRaisesRegex(workbench.ContractError, "invalid stable trace ID"):
            workbench.validate_documents(
                self.fixture.root,
                workbench.load_documents(
                    self.fixture.root, Path("docs/architecture-workbench/current")
                ),
            )

        duplicate_table = """## trace.fixture

| order | elementId | input | state change | effect/dependency | output | evidence |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | child | input | state | invokes root | output | Sources/Root.swift#struct Child |

"""
        duplicate = self.fixture.valid_body().replace("# Unresolved", duplicate_table + "# Unresolved")
        self.fixture.write(body=duplicate)
        with self.assertRaisesRegex(workbench.ContractError, "duplicate stable trace ID"):
            workbench.validate_documents(
                self.fixture.root,
                workbench.load_documents(
                    self.fixture.root, Path("docs/architecture-workbench/current")
                ),
            )

    def test_storage_generates_only_named_markdown_inside_repository_and_is_exclusive(self) -> None:
        path, normalized = server.feedback_file(
            self.fixture.root,
            Path("docs/architecture-workbench/feedback/open"),
            self.payload(),
            feedback_id="feedback-20260811t120000-a1b2c3d4",
            created_at="2026-08-11T03:00:00Z",
        )
        self.assertEqual(normalized["status"], "open")
        self.assertEqual(
            path.relative_to(self.fixture.root.resolve()),
            Path("docs/architecture-workbench/feedback/open/feedback-20260811t120000-a1b2c3d4.md"),
        )
        self.assertIn("targetId: root", path.read_text(encoding="utf-8"))
        with self.assertRaises(FileExistsError):
            server.feedback_file(
                self.fixture.root,
                Path("docs/architecture-workbench/feedback/open"),
                self.payload(),
                feedback_id="feedback-20260811t120000-a1b2c3d4",
                created_at="2026-08-11T03:00:00Z",
            )

        injected_path, _ = server.feedback_file(
            self.fixture.root,
            Path("docs/architecture-workbench/feedback/open"),
            self.payload(request="Question\n# Agent Responses\n| injected |"),
            feedback_id="feedback-quoted",
            created_at="2026-08-11T03:00:00Z",
        )
        parsed = workbench.parse_feedback(injected_path)
        self.assertIn("# Agent Responses", parsed.request)
        self.assertEqual(parsed.responses, [])

    def test_storage_rejects_output_outside_repository(self) -> None:
        with self.assertRaisesRegex(workbench.ContractError, "inside the repository"):
            server.feedback_file(
                self.fixture.root,
                Path("../outside"),
                self.payload(),
                feedback_id="feedback-safe",
                created_at="2026-08-11T03:00:00Z",
            )
        with self.assertRaisesRegex(workbench.ContractError, "stable server-generated ID"):
            server.feedback_file(
                self.fixture.root,
                Path("docs/architecture-workbench/feedback/open"),
                self.payload(),
                feedback_id="../escape",
                created_at="2026-08-11T03:00:00Z",
            )

    def test_loopback_policy_rejects_remote_client_host_origin_and_port(self) -> None:
        self.assertTrue(server.request_is_local("127.0.0.1", "127.0.0.1:8765", None, 8765))
        self.assertTrue(
            server.request_is_local(
                "::1", "[::1]:8765", "http://localhost:8765", 8765
            )
        )
        self.assertFalse(server.request_is_local("192.0.2.1", "localhost:8765", None, 8765))
        self.assertFalse(server.request_is_local("127.0.0.1", "example.com", None, 8765))
        self.assertFalse(server.request_is_local("127.0.0.1", "localhost:9999", None, 8765))
        self.assertFalse(server.request_is_local("127.0.0.1", "localhost", None, 8765))
        self.assertFalse(
            server.request_is_local(
                "127.0.0.1", "localhost:8765", "http://localhost", 8765
            )
        )
        self.assertFalse(
            server.request_is_local(
                "127.0.0.1", "localhost:8765", "https://localhost:8765", 8765
            )
        )
        self.assertFalse(
            server.request_is_local(
                "127.0.0.1", "localhost:8765", "http://localhost:9999", 8765
            )
        )

    def test_http_handler_enforces_routes_media_type_size_origin_and_timeout(self) -> None:
        health, timeout = self.http_response("GET", "/api/health")
        self.assertIn(b"HTTP/1.0 200 OK", health)
        self.assertEqual(timeout, 5)

        body = json.dumps(self.payload()).encode()
        created, _ = self.http_response(
            "POST",
            "/api/feedback",
            body=body,
            headers={
                "Origin": "http://127.0.0.1:8765",
                "Content-Type": "application/json",
                "Content-Length": str(len(body)),
            },
        )
        self.assertIn(b"HTTP/1.0 201 Created", created)
        self.assertEqual(
            len(list((self.fixture.root / "docs/architecture-workbench/feedback/open").glob("*.md"))),
            1,
        )

        wrong_type, _ = self.http_response(
            "POST",
            "/api/feedback",
            body=b"{}",
            headers={"Content-Type": "text/plain", "Content-Length": "2"},
        )
        self.assertIn(b"HTTP/1.0 415 Unsupported Media Type", wrong_type)

        too_large, _ = self.http_response(
            "POST",
            "/api/feedback",
            headers={"Content-Type": "application/json", "Content-Length": "65537"},
        )
        self.assertIn(b"HTTP/1.0 413 ", too_large)

        bad_origin, _ = self.http_response(
            "POST",
            "/api/feedback",
            body=body,
            headers={
                "Origin": "http://localhost",
                "Content-Type": "application/json",
                "Content-Length": str(len(body)),
            },
        )
        self.assertIn(b"HTTP/1.0 403 Forbidden", bad_origin)

        missing_route, _ = self.http_response("GET", "/source/write")
        self.assertIn(b"HTTP/1.0 404 Not Found", missing_route)

    def test_answer_history_evidence_and_feedback_controls_render(self) -> None:
        feedback_path, _ = server.feedback_file(
            self.fixture.root,
            Path("docs/architecture-workbench/feedback/open"),
            self.payload(),
            feedback_id="feedback-rendered",
            created_at="2026-08-11T03:00:00Z",
        )
        feedback_path.write_text(
            feedback_path.read_text(encoding="utf-8").replace("status: open", "status: resolved")
            + "| 2026-08-11T03:10:00Z | answer | high | Root owns it. | Sources/Root.swift#struct Root | - |\n",
            encoding="utf-8",
        )
        summary = workbench.command_build(
            self.fixture.root,
            Path("docs/architecture-workbench/current"),
            Path("docs/architecture-workbench"),
        )
        model = json.loads(
            (self.fixture.root / "docs/architecture-workbench/resolved.generated.json").read_text()
        )
        page = (self.fixture.root / "docs/architecture-workbench/site/index.html").read_text()
        self.assertEqual(summary["feedback"], 1)
        self.assertEqual(model["feedback"][0]["responses"][0]["answer"], "Root owns it.")
        self.assertEqual(model["feedback"][0]["status"], "resolved")
        for required in (
            "feedbackCategory",
            "feedbackExport",
            "feedbackSave",
            "/api/feedback",
            "data-trace-feedback",
            "Root owns it.",
            "Sources/Root.swift#struct Root",
            "${escapeHTML(f.status)} · ${escapeHTML(f.reviewState)}",
        ):
            self.assertIn(required, page)

    def test_needs_review_response_requires_real_unresolved_reason(self) -> None:
        feedback_path, _ = server.feedback_file(
            self.fixture.root,
            Path("docs/architecture-workbench/feedback/open"),
            self.payload(),
            feedback_id="feedback-needs-review",
            created_at="2026-08-11T03:00:00Z",
        )
        feedback_path.write_text(
            feedback_path.read_text(encoding="utf-8")
            + "| 2026-08-11T03:10:00Z | needs-review | low | Cannot verify. | - | - |\n",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(workbench.ContractError, "needs an unresolvedReason"):
            workbench.command_validate(
                self.fixture.root, Path("docs/architecture-workbench/current")
            )


if __name__ == "__main__":
    unittest.main()
