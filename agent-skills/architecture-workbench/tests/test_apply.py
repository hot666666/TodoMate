import json
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path

from test_proposed import ProposalFixture, proposal


class ApplyTests(unittest.TestCase):
    def setUp(self):
        self.fixture = ProposalFixture()
        self.path = self.fixture.prepare()
        self.item = proposal.parse_proposal(self.path, self.fixture.root)
        self.approval = self.fixture.root / "approval.json"
        self.nonce = "fixture-current-turn-nonce-0123456789abcdef"

    def tearDown(self):
        self.fixture.close()

    def write_approval(self, **overrides):
        payload = {
            "schemaVersion": "1",
            "proposalId": "proposal.fixture",
            "proposalDigest": proposal.proposal_digest(self.item),
            "baseGitCommit": self.fixture.commit,
            "approvedInCurrentTurn": True,
            "approvedAt": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "approvalNote": "Explicit approval in this test turn.",
            "turnNonceHash": proposal.sha256(self.nonce.encode("utf-8")),
        }
        payload.update(overrides)
        self.approval.write_text(json.dumps(payload), encoding="utf-8")

    def test_apply_requires_current_turn_approval_and_leaves_targets_unchanged(self):
        targets = [self.fixture.root / row["targetPath"] for row in self.item.files]
        before = [path.read_bytes() for path in targets]
        with self.assertRaises(FileNotFoundError):
            proposal.apply_proposal(self.fixture.root, self.item, self.approval, self.nonce)
        self.assertEqual(before, [path.read_bytes() for path in targets])

    def test_mismatched_digest_is_rejected_without_mutation(self):
        self.write_approval(proposalDigest="0" * 64)
        target = self.fixture.root / "Sources/Feature.swift"
        before = target.read_bytes()
        with self.assertRaisesRegex(proposal.base.ContractError, "proposalDigest"):
            proposal.apply_proposal(self.fixture.root, self.item, self.approval, self.nonce)
        self.assertEqual(before, target.read_bytes())

    def test_stale_self_attested_approval_is_rejected(self):
        self.write_approval(approvedAt="1970-01-01T00:00:00Z")
        with self.assertRaisesRegex(proposal.base.ContractError, "not fresh"):
            proposal.apply_proposal(self.fixture.root, self.item, self.approval, self.nonce)

    def test_approval_cannot_be_replayed_without_transient_turn_nonce(self):
        self.write_approval()
        with self.assertRaisesRegex(proposal.base.ContractError, "transient current-turn nonce"):
            proposal.apply_proposal(self.fixture.root, self.item, self.approval, "different-current-turn-nonce-0123456789")

    def test_approved_apply_updates_code_and_current_then_reconciles(self):
        self.write_approval()
        result = proposal.apply_proposal(self.fixture.root, self.item, self.approval, self.nonce)
        self.assertTrue(result["implemented"])
        for row in self.item.files:
            self.assertEqual(
                (self.fixture.root / row["targetPath"]).read_bytes(),
                (self.item.directory / row["proposedPath"]).read_bytes(),
            )

    def test_reconcile_never_reports_diverged_result_as_implemented(self):
        self.write_approval()
        proposal.apply_proposal(self.fixture.root, self.item, self.approval, self.nonce)
        (self.fixture.root / "Sources/Feature.swift").write_text("struct Diverged {}\n")
        with self.assertRaisesRegex(proposal.base.ContractError, "not implemented"):
            proposal.reconcile_proposal(self.fixture.root, self.item)

    def test_reconcile_failure_rolls_back_every_applied_target(self):
        self.write_approval()
        targets = [self.fixture.root / row["targetPath"] for row in self.item.files]
        before = [path.read_bytes() for path in targets]
        proposed_current = self.item.directory / "files/architecture.md"
        proposed_current.write_text("not valid architecture markdown\n", encoding="utf-8")
        self.write_approval()
        with self.assertRaises(proposal.base.ContractError):
            proposal.apply_proposal(self.fixture.root, self.item, self.approval, self.nonce)
        self.assertEqual(before, [path.read_bytes() for path in targets])

    def test_fresh_parse_reconcile_and_canonical_validate_work_after_apply(self):
        self.write_approval()
        proposal.apply_proposal(self.fixture.root, self.item, self.approval, self.nonce)
        fresh = proposal.parse_proposal(self.path, self.fixture.root)
        self.assertTrue(proposal.reconcile_proposal(self.fixture.root, fresh)["implemented"])
        proposal.base.command_validate(self.fixture.root, Path("docs/architecture-workbench/current"))

    def test_parent_symlink_cannot_escape_repository(self):
        with tempfile.TemporaryDirectory() as outside_directory:
            outside = Path(outside_directory) / "workbench-outside.swift"
            outside.write_text("outside\n", encoding="utf-8")
            link = self.fixture.root / "Linked"
            link.symlink_to(outside.parent, target_is_directory=True)
            row = self.item.files[0]
            row["targetPath"] = f"Linked/{outside.name}"
            row["expectedSHA256"] = proposal.sha256(outside.read_bytes())
            self.write_approval()
            with self.assertRaisesRegex(proposal.base.ContractError, "escapes repository"):
                proposal.apply_proposal(self.fixture.root, self.item, self.approval, self.nonce)
            self.assertEqual(b"outside\n", outside.read_bytes())


if __name__ == "__main__":
    unittest.main()
