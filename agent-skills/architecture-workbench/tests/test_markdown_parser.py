import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "scripts" / "architecture_workbench.py"
SPEC = importlib.util.spec_from_file_location("architecture_workbench", SCRIPT)
workbench = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = workbench
SPEC.loader.exec_module(workbench)


def git(root: Path, *arguments: str) -> str:
    return subprocess.run(
        ["git", *arguments], cwd=root, check=True, text=True, stdout=subprocess.PIPE
    ).stdout.strip()


class RepositoryFixture:
    def __init__(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "docs/architecture-workbench/current").mkdir(parents=True)
        (self.root / "Sources").mkdir()
        (self.root / "Sources/Root.swift").write_text(
            "struct Root {}\nstruct Child {}\n", encoding="utf-8"
        )
        git(self.root, "init", "-q")
        git(self.root, "config", "user.email", "workbench@example.invalid")
        git(self.root, "config", "user.name", "Workbench Tests")
        git(self.root, "add", "Sources/Root.swift")
        git(self.root, "commit", "-qm", "fixture source")
        self.commit = git(self.root, "rev-parse", "HEAD")

    def close(self) -> None:
        self.temp.cleanup()

    def write(self, name: str = "architecture.md", body: str | None = None) -> Path:
        body = body or self.valid_body()
        path = self.root / "docs/architecture-workbench/current" / name
        path.write_text(body, encoding="utf-8")
        return path

    def valid_body(self) -> str:
        return f"""---
schemaVersion: 1
documentId: current.architecture
modelLayer: architecture
verifiedGitCommit: {self.commit}
status: current
---

# Fixture

# Nodes

## root

- kind: repository
- summary: Root node.
- parent: -
- module: Fixture
- status: observed
- confidence: high
- source: Sources/Root.swift#struct Root

## child

- kind: module
- summary: Child node.
- parent: root
- module: Fixture
- status: observed
- confidence: high
- source: Sources/Root.swift#struct Child

# Relationships

| sourceId | kind | targetId | status | confidence | evidence |
| --- | --- | --- | --- | --- | --- |
| child | depends-on | root | observed | high | Sources/Root.swift#struct Child |

# Hierarchy

| parentId | childId | relationship | condition | evidence |
| --- | --- | --- | --- | --- |
| root | child | contains | always | Sources/Root.swift#struct Child |

# Traces

## trace.fixture

| order | elementId | input | state change | effect/dependency | output | evidence |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | child | input | state | invokes root | output | Sources/Root.swift#struct Child |

# Unresolved

| elementId | reason | verificationSuggestion | evidence |
| --- | --- | --- | --- |
"""


class MarkdownContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture = RepositoryFixture()

    def tearDown(self) -> None:
        self.fixture.close()

    def validate(self) -> dict:
        documents = workbench.load_documents(
            self.fixture.root, Path("docs/architecture-workbench/current")
        )
        return workbench.validate_documents(self.fixture.root, documents)

    def test_valid_markdown_resolves_nodes_relationships_hierarchy_and_trace(self) -> None:
        self.fixture.write()
        summary = self.validate()
        self.assertEqual(summary["nodes"], 2)
        self.assertEqual(summary["relationships"], 1)
        self.assertEqual(summary["hierarchy"], 1)
        self.assertEqual(summary["traces"], 1)

    def test_duplicate_id_is_rejected(self) -> None:
        self.fixture.write()
        second = self.fixture.valid_body().replace(
            "documentId: current.architecture", "documentId: current.second"
        )
        self.fixture.write("second.md", second)
        with self.assertRaisesRegex(workbench.ContractError, "duplicate stable node ID"):
            self.validate()

    def test_dangling_relationship_is_rejected(self) -> None:
        self.fixture.write(body=self.fixture.valid_body().replace("targetId |", "targetId |").replace(
            "| child | depends-on | root |", "| child | depends-on | missing |"
        ))
        with self.assertRaisesRegex(workbench.ContractError, "dangling relationship"):
            self.validate()

    def test_invalid_parent_is_rejected(self) -> None:
        self.fixture.write(body=self.fixture.valid_body().replace("- parent: root", "- parent: missing"))
        with self.assertRaisesRegex(workbench.ContractError, "invalid parent"):
            self.validate()

    def test_missing_evidence_is_rejected(self) -> None:
        self.fixture.write(body=self.fixture.valid_body().replace(
            "| child | depends-on | root | observed | high | Sources/Root.swift#struct Child |",
            "| child | depends-on | root | observed | high | |",
        ))
        with self.assertRaisesRegex(workbench.ContractError, "missing evidence"):
            self.validate()

    def test_stale_source_path_and_symbol_are_rejected(self) -> None:
        body = self.fixture.valid_body().replace(
            "Sources/Root.swift#struct Root", "Sources/Missing.swift#Missing", 1
        ).replace("Sources/Root.swift#struct Child", "Sources/Root.swift#Missing", 1)
        self.fixture.write(body=body)
        with self.assertRaises(workbench.ContractError) as context:
            self.validate()
        self.assertIn("stale source path", str(context.exception))
        self.assertIn("stale source symbol", str(context.exception))

    def test_source_change_after_verified_commit_is_rejected(self) -> None:
        self.fixture.write()
        (self.fixture.root / "Sources/Root.swift").write_text(
            "struct Root {}\nstruct Child { let changed = true }\n", encoding="utf-8"
        )
        git(self.fixture.root, "add", "Sources/Root.swift")
        git(self.fixture.root, "commit", "-qm", "change cited source")
        with self.assertRaisesRegex(workbench.ContractError, "source evidence changed"):
            self.validate()

    def test_untracked_source_absent_at_verified_commit_is_rejected(self) -> None:
        (self.fixture.root / "Sources/Untracked.swift").write_text(
            "struct Untracked {}\n", encoding="utf-8"
        )
        body = self.fixture.valid_body().replace(
            "Sources/Root.swift#struct Root", "Sources/Untracked.swift#struct Untracked", 1
        )
        self.fixture.write(body=body)
        with self.assertRaisesRegex(workbench.ContractError, "absent at verifiedGitCommit"):
            self.validate()

    def test_hierarchy_cycle_is_rejected(self) -> None:
        body = self.fixture.valid_body().replace(
            "| root | child | contains | always | Sources/Root.swift#struct Child |",
            "| root | child | contains | always | Sources/Root.swift#struct Child |\n"
            "| child | root | contains | always | Sources/Root.swift#struct Root |",
        )
        self.fixture.write(body=body)
        with self.assertRaisesRegex(workbench.ContractError, "hierarchy cycle"):
            self.validate()


if __name__ == "__main__":
    unittest.main()
