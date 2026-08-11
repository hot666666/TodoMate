import hashlib
import importlib.util
import json
import shutil
import sys
import unittest
from pathlib import Path

from test_markdown_parser import RepositoryFixture


SCRIPT = Path(__file__).parents[1] / "scripts" / "proposal_workbench.py"
SPEC = importlib.util.spec_from_file_location("proposal_workbench_tests", SCRIPT)
proposal = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = proposal
SPEC.loader.exec_module(proposal)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class ProposalFixture(RepositoryFixture):
    def prepare(self) -> Path:
        current = self.write()
        feedback_dir = self.root / "docs/architecture-workbench/feedback/open"
        feedback_dir.mkdir(parents=True)
        (feedback_dir / "feedback.fixture.md").write_text(f"""---
schemaVersion: 1
feedbackId: feedback.fixture
targetId: child
targetDocumentId: current.architecture
verifiedGitCommit: {self.commit}
category: code-change-request
status: correction-proposed
createdAt: 2026-08-11T00:00:00Z
---

# Request

> Change the fixture architecture.

# Context

> Fixture round trip.

# Agent Responses

| respondedAt | disposition | confidence | answer | evidence | unresolvedReason |
| --- | --- | --- | --- | --- | --- |
| 2026-08-11T00:01:00Z | correction-proposed | high | Proposal prepared. | Sources/Root.swift#struct Child | - |
""", encoding="utf-8")
        feature = self.root / "Sources/Feature.swift"
        feature.write_text("struct Feature { let version = 1 }\n", encoding="utf-8")
        proposal_dir = self.root / "docs/architecture-workbench/proposed/proposal.fixture"
        (proposal_dir / "files").mkdir(parents=True)
        (proposal_dir / "snapshot").mkdir()
        proposed_current = self.valid_body().replace(
            "summary: Child node.", "summary: Proposed child node."
        ).replace("| child | depends-on | root |", "| child | invokes | root |").replace(
            "| root | child | contains |", "| root | child | composes |"
        ).replace("| 1 | child | input |", "| 1 | child | proposed-input |")
        (proposal_dir / "files/Feature.swift").write_text(
            "struct Feature { let version = 2 }\n", encoding="utf-8"
        )
        (proposal_dir / "files/architecture.md").write_text(proposed_current, encoding="utf-8")
        (proposal_dir / "snapshot/architecture.md").write_text(
            proposed_current.replace("status: current", "status: proposed", 1), encoding="utf-8"
        )
        (proposal_dir / "proposal.md").write_text(f"""---
schemaVersion: 1
proposalId: proposal.fixture
feedbackId: feedback.fixture
baseGitCommit: {self.commit}
status: proposed
---

# Summary

Change the fixture architecture and code together.

# Files

| targetPath | proposedPath | expectedSHA256 | role |
| --- | --- | --- | --- |
| Sources/Feature.swift | files/Feature.swift | {digest(feature)} | code |
| docs/architecture-workbench/current/architecture.md | files/architecture.md | {digest(current)} | current-markdown |
""", encoding="utf-8")
        return proposal_dir / "proposal.md"


class ProposedPreviewTests(unittest.TestCase):
    def setUp(self):
        self.fixture = ProposalFixture()
        self.path = self.fixture.prepare()

    def tearDown(self):
        self.fixture.close()

    def test_preview_reports_stable_id_diffs_without_mutating_current_or_code(self):
        before = {path: path.read_bytes() for path in [
            self.fixture.root / "Sources/Feature.swift",
            self.fixture.root / "docs/architecture-workbench/current/architecture.md",
        ]}
        item = proposal.parse_proposal(self.path, self.fixture.root)
        current = proposal.base.load_documents(self.fixture.root, Path("docs/architecture-workbench/current"))
        preview = proposal.diff_proposal(current, item)
        self.assertEqual({change["section"] for change in preview["changes"]}, {"nodes", "relationships", "hierarchy", "traces"})
        self.assertEqual(before, {path: path.read_bytes() for path in before})

    def test_generated_explorer_contains_as_is_to_be_and_diff(self):
        architecture = proposal.base
        architecture.command_build(self.fixture.root, Path("docs/architecture-workbench/current"), Path("docs/architecture-workbench"))
        page = (self.fixture.root / "docs/architecture-workbench/site/index.html").read_text()
        model = json.loads((self.fixture.root / "docs/architecture-workbench/resolved.generated.json").read_text())
        self.assertEqual(model["proposals"][0]["proposalId"], "proposal.fixture")
        for text in ("Proposed Changes", "As-Is", "To-Be", "Diff"):
            self.assertIn(text, page)

    def test_current_replacement_must_equal_preview_snapshot(self):
        replacement = self.path.parent / "files/architecture.md"
        replacement.write_text(
            replacement.read_text().replace("Proposed child node.", "Unpreviewed child node."),
            encoding="utf-8",
        )
        with self.assertRaisesRegex(proposal.base.ContractError, "does not match preview snapshot"):
            proposal.parse_proposal(self.path, self.fixture.root)

    def test_linked_feedback_contract_is_validated(self):
        feedback = self.fixture.root / "docs/architecture-workbench/feedback/open/feedback.fixture.md"
        feedback.write_text(feedback.read_text().replace("targetId: child", "targetId: missing"), encoding="utf-8")
        with self.assertRaisesRegex(proposal.base.ContractError, "feedback target"):
            proposal.parse_proposal(self.path, self.fixture.root)


if __name__ == "__main__":
    unittest.main()
