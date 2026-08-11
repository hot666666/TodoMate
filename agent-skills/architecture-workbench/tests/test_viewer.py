import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

from test_markdown_parser import RepositoryFixture


SCRIPT = Path(__file__).parents[1] / "scripts" / "architecture_workbench.py"
SPEC = importlib.util.spec_from_file_location("architecture_workbench_viewer", SCRIPT)
workbench = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = workbench
SPEC.loader.exec_module(workbench)


class ViewerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture = RepositoryFixture()
        self.fixture.write()

    def tearDown(self) -> None:
        self.fixture.close()

    def test_deleted_outputs_rebuild_deterministically_from_markdown(self) -> None:
        docs = Path("docs/architecture-workbench/current")
        output = Path("docs/architecture-workbench")
        workbench.command_build(self.fixture.root, docs, output)
        json_path = self.fixture.root / output / "resolved.generated.json"
        html_path = self.fixture.root / output / "site/index.html"
        first_json = json_path.read_bytes()
        first_html = html_path.read_bytes()
        json_path.unlink()
        html_path.unlink()
        workbench.command_build(self.fixture.root, docs, output)
        self.assertEqual(first_json, json_path.read_bytes())
        self.assertEqual(first_html, html_path.read_bytes())

    def test_resolved_model_and_offline_explorer_include_required_surfaces(self) -> None:
        workbench.command_build(
            self.fixture.root,
            Path("docs/architecture-workbench/current"),
            Path("docs/architecture-workbench"),
        )
        model = json.loads(
            (self.fixture.root / "docs/architecture-workbench/resolved.generated.json").read_text()
        )
        page = (self.fixture.root / "docs/architecture-workbench/site/index.html").read_text()
        self.assertEqual([node["id"] for node in model["nodes"]], ["root", "child"])
        for required in (
            'id="search"',
            'id="layer"',
            'id="kind"',
            'id="inspector"',
            'data-view="hierarchy"',
            'data-view="traces"',
            'data-tree-toggle',
            'aria-expanded="true"',
            ".disabled=b.dataset.view!=='graph'",
            "Upstream",
            "Downstream",
            "#node=",
        ):
            self.assertIn(required, page)
        self.assertNotIn("https://", page)

    def test_common_skill_has_no_project_name_hardcoding(self) -> None:
        skill_root = Path(__file__).parents[1]
        inspected = [skill_root / "SKILL.md", *skill_root.glob("references/*.md"), *skill_root.glob("scripts/*.py")]
        project_name = "Todo" + "Mate"
        for path in inspected:
            self.assertNotIn(project_name, path.read_text(encoding="utf-8"), str(path))


if __name__ == "__main__":
    unittest.main()
