import importlib.util
import json
import sys
import unittest
from pathlib import Path

from test_markdown_parser import RepositoryFixture, git, workbench


SERVER_SCRIPT = Path(__file__).parents[1] / "scripts" / "feedback_server.py"
SERVER_SPEC = importlib.util.spec_from_file_location("architecture_workbench_feedback_server", SERVER_SCRIPT)
server = importlib.util.module_from_spec(SERVER_SPEC)
assert SERVER_SPEC.loader is not None
sys.modules[SERVER_SPEC.name] = server
SERVER_SPEC.loader.exec_module(server)


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

    def test_answer_history_evidence_and_feedback_controls_render(self) -> None:
        feedback_path, _ = server.feedback_file(
            self.fixture.root,
            Path("docs/architecture-workbench/feedback/open"),
            self.payload(),
            feedback_id="feedback-rendered",
            created_at="2026-08-11T03:00:00Z",
        )
        feedback_path.write_text(
            feedback_path.read_text(encoding="utf-8")
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
        for required in (
            "feedbackCategory",
            "feedbackExport",
            "feedbackSave",
            "/api/feedback",
            "data-trace-feedback",
            "Root owns it.",
            "Sources/Root.swift#struct Root",
        ):
            self.assertIn(required, page)


if __name__ == "__main__":
    unittest.main()
