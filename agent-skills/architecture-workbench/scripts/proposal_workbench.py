#!/usr/bin/env python3
"""Validate, preview, approve, apply, and reconcile Architecture Workbench proposals."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Iterable


SCRIPT = Path(__file__).with_name("architecture_workbench.py")
SPEC = importlib.util.spec_from_file_location("architecture_workbench_proposal_base", SCRIPT)
base = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = base
SPEC.loader.exec_module(base)

SCHEMA_VERSION = "1"
PROPOSAL_FIELDS = {"schemaVersion", "proposalId", "feedbackId", "baseGitCommit", "status"}
APPROVAL_FIELDS = {
    "schemaVersion", "proposalId", "proposalDigest", "baseGitCommit",
    "approvedInCurrentTurn", "approvedAt", "approvalNote",
}
FILE_COLUMNS = {"targetPath", "proposedPath", "expectedSHA256", "role"}
ROLES = {"code", "current-markdown", "test"}


@dataclass
class Proposal:
    directory: Path
    path: Path
    frontmatter: dict[str, str]
    summary: str
    files: list[dict[str, str]]
    snapshot: list[Any]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def safe_relative(value: str, owner: str) -> Path:
    path = Path(value)
    if path.is_absolute() or ".." in path.parts or not path.parts or ".git" in path.parts:
        raise base.ContractError(f"{owner}: unsafe repository-relative path {value!r}")
    return path


def parse_proposal(path: Path, root: Path) -> Proposal:
    frontmatter, lines = base.parse_frontmatter(path.read_text(encoding="utf-8"), path)
    errors: list[str] = []
    missing = sorted(PROPOSAL_FIELDS - frontmatter.keys())
    extra = sorted(frontmatter.keys() - PROPOSAL_FIELDS)
    if missing:
        errors.append(f"missing proposal frontmatter fields: {', '.join(missing)}")
    if extra:
        errors.append(f"unsupported proposal frontmatter fields: {', '.join(extra)}")
    if frontmatter.get("schemaVersion") != SCHEMA_VERSION:
        errors.append(f"proposal schemaVersion must be {SCHEMA_VERSION}")
    if frontmatter.get("status") != "proposed":
        errors.append("proposal status must be proposed")
    for field in ("proposalId", "feedbackId"):
        if not base.STABLE_ID.fullmatch(frontmatter.get(field, "")):
            errors.append(f"invalid {field} {frontmatter.get(field, '')!r}")
    feedback_items = base.load_feedback(root, Path("docs/architecture-workbench/feedback"))
    feedback_ids = {item.frontmatter.get("feedbackId", "") for item in feedback_items}
    if frontmatter.get("feedbackId") not in feedback_ids:
        errors.append("feedbackId does not resolve to feedback Markdown")
    linked_feedback = next(
        (item for item in feedback_items if item.frontmatter.get("feedbackId") == frontmatter.get("feedbackId")),
        None,
    )
    if linked_feedback is not None and linked_feedback.frontmatter.get("category") != "code-change-request":
        errors.append("proposal feedback must have category code-change-request")
    commit = frontmatter.get("baseGitCommit", "")
    if not base.COMMIT.fullmatch(commit):
        errors.append("baseGitCommit must be a 40-character lowercase SHA")
    elif base.run_git(root, ["cat-file", "-e", f"{commit}^{{commit}}"], check=False).returncode != 0:
        errors.append(f"baseGitCommit does not exist: {commit}")
    elif base.run_git(root, ["merge-base", "--is-ancestor", commit, "HEAD"], check=False).returncode != 0:
        errors.append("baseGitCommit must be an ancestor of HEAD")

    sections: dict[str, list[str]] = {"Summary": [], "Files": []}
    section = ""
    for line in lines:
        if line.startswith("# ") and not line.startswith("## "):
            section = line[2:].strip()
        elif section in sections:
            sections[section].append(line)
    summary = "\n".join(sections["Summary"]).strip()
    if not summary:
        errors.append("proposal Summary must not be empty")
    files = base.table_rows(sections["Files"], path, "Files")
    base.require_columns(files, FILE_COLUMNS, path, "Files", errors)
    roles: set[str] = set()
    targets: set[Path] = set()
    for row in files:
        target = safe_relative(row.get("targetPath", ""), str(path))
        proposed = safe_relative(row.get("proposedPath", ""), str(path))
        if target in targets:
            errors.append(f"duplicate proposal target {target}")
        targets.add(target)
        role = row.get("role", "")
        roles.add(role)
        if role not in ROLES:
            errors.append(f"unsupported proposal file role {role!r}")
        if role == "current-markdown" and target.parts[:3] != ("docs", "architecture-workbench", "current"):
            errors.append(f"current-markdown target is outside current/: {target}")
        candidate = path.parent / proposed
        if not candidate.is_file() or not candidate.resolve().is_relative_to(path.parent.resolve()):
            errors.append(f"missing proposed file {proposed}")
        expected = row.get("expectedSHA256", "")
        current = root / target
        if not re.fullmatch(r"[0-9a-f]{64}", expected):
            errors.append(f"invalid expectedSHA256 for {target}")
        elif not current.is_file() or sha256(current.read_bytes()) != expected:
            errors.append(f"target drifted from expectedSHA256: {target}")
    if "code" in roles and "current-markdown" not in roles:
        errors.append("a code proposal must update current Markdown in the same apply set")

    snapshot_dir = path.parent / "snapshot"
    snapshot = []
    if not snapshot_dir.is_dir() or not list(snapshot_dir.glob("*.md")):
        errors.append("proposal must include a non-empty snapshot directory")
    else:
        snapshot = base.load_documents(root, snapshot_dir.relative_to(root))
        for document in snapshot:
            if document.frontmatter.get("status") != "proposed":
                errors.append(f"{document.path.relative_to(root)}: proposal snapshot status must be proposed")
            document.frontmatter["status"] = "current"
        try:
            base.validate_documents(root, snapshot)
        finally:
            for document in snapshot:
                document.frontmatter["status"] = "proposed"
    if errors:
        raise base.ContractError(f"{path.relative_to(root)}: " + "\n".join(errors))
    return Proposal(path.parent, path, frontmatter, summary, files, snapshot)


def load_proposals(root: Path, directory: Path) -> list[Proposal]:
    absolute = root / directory
    if not absolute.exists():
        return []
    paths = sorted(absolute.glob("*/proposal.md"))
    proposals = [parse_proposal(path, root) for path in paths]
    ids = [item.frontmatter["proposalId"] for item in proposals]
    if len(ids) != len(set(ids)):
        raise base.ContractError("duplicate proposalId")
    return proposals


def proposal_digest(proposal: Proposal) -> str:
    digest = hashlib.sha256()
    digest.update(proposal.path.read_bytes())
    for row in sorted(proposal.files, key=lambda item: item["targetPath"]):
        digest.update(row["targetPath"].encode())
        digest.update((proposal.directory / row["proposedPath"]).read_bytes())
    for path in sorted((proposal.directory / "snapshot").glob("*.md")) if (proposal.directory / "snapshot").is_dir() else []:
        digest.update(path.relative_to(proposal.directory).as_posix().encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()


def keyed(document: Any, section: str) -> dict[str, dict[str, Any]]:
    values = getattr(document, section)
    if section == "nodes":
        return {row["id"]: row for row in values}
    if section == "relationships":
        return {f"{row['sourceId']}|{row['kind']}|{row['targetId']}": row for row in values}
    if section == "hierarchy":
        return {f"{row['parentId']}|{row['relationship']}|{row['childId']}": row for row in values}
    return {f"{row['traceId']}|{row['order']}|{row['elementId']}": row for row in values}


def diff_proposal(current: list[Any], proposal: Proposal) -> dict[str, Any]:
    result: list[dict[str, Any]] = []
    current_by_doc = {d.frontmatter["documentId"]: d for d in current}
    proposed_by_doc = {d.frontmatter["documentId"]: d for d in proposal.snapshot}
    for section in ("nodes", "relationships", "hierarchy", "traces"):
        before: dict[str, dict[str, Any]] = {}
        after: dict[str, dict[str, Any]] = {}
        for document_id, document in current_by_doc.items():
            before.update({f"{document_id}:{key}": value for key, value in keyed(document, section).items()})
        for document_id, document in proposed_by_doc.items():
            after.update({f"{document_id}:{key}": value for key, value in keyed(document, section).items()})
        for identity in sorted(set(before) | set(after)):
            if before.get(identity) != after.get(identity):
                change = "added" if identity not in before else "removed" if identity not in after else "changed"
                result.append({"section": section, "id": identity, "change": change, "asIs": before.get(identity), "toBe": after.get(identity)})
    return {
        "proposalId": proposal.frontmatter["proposalId"],
        "feedbackId": proposal.frontmatter["feedbackId"],
        "summary": proposal.summary,
        "baseGitCommit": proposal.frontmatter["baseGitCommit"],
        "digest": proposal_digest(proposal),
        "changes": result,
    }


def validate_approval(proposal: Proposal, approval_path: Path) -> dict[str, Any]:
    payload = json.loads(approval_path.read_text(encoding="utf-8"))
    if set(payload) != APPROVAL_FIELDS:
        raise base.ContractError("approval fields do not match the approval contract")
    if payload["schemaVersion"] != SCHEMA_VERSION or payload["proposalId"] != proposal.frontmatter["proposalId"]:
        raise base.ContractError("approval does not identify this proposal")
    if payload["proposalDigest"] != proposal_digest(proposal):
        raise base.ContractError("approval proposalDigest does not match current proposal content")
    if payload["baseGitCommit"] != proposal.frontmatter["baseGitCommit"]:
        raise base.ContractError("approval baseGitCommit does not match proposal")
    if payload["approvedInCurrentTurn"] is not True or not str(payload["approvalNote"]).strip():
        raise base.ContractError("approval must record explicit current-turn approval and a note")
    if not base.valid_iso8601(payload["approvedAt"]):
        raise base.ContractError("approval approvedAt must be ISO-8601")
    return payload


def apply_proposal(root: Path, proposal: Proposal, approval_path: Path) -> dict[str, Any]:
    validate_approval(proposal, approval_path)
    prepared: list[tuple[Path, bytes, bytes]] = []
    for row in proposal.files:
        target = root / safe_relative(row["targetPath"], str(proposal.path))
        before = target.read_bytes()
        if sha256(before) != row["expectedSHA256"]:
            raise base.ContractError(f"target drifted before apply: {target.relative_to(root)}")
        after = (proposal.directory / row["proposedPath"]).read_bytes()
        prepared.append((target, before, after))
    staged: list[tuple[Path, Path, bytes]] = []
    written: list[tuple[Path, bytes]] = []
    try:
        for target, before, after in prepared:
            temporary = target.with_name(f".{target.name}.workbench-{os.getpid()}")
            temporary.write_bytes(after)
            temporary.chmod(target.stat().st_mode)
            staged.append((target, temporary, before))
        for target, temporary, before in staged:
            os.replace(temporary, target)
            written.append((target, before))
        return reconcile_proposal(root, proposal)
    except Exception:
        for target, before in reversed(written):
            target.write_bytes(before)
        raise
    finally:
        for _, temporary, _ in staged:
            temporary.unlink(missing_ok=True)


def reconcile_proposal(root: Path, proposal: Proposal) -> dict[str, Any]:
    mismatches = []
    for row in proposal.files:
        target = root / row["targetPath"]
        proposed = proposal.directory / row["proposedPath"]
        if not target.is_file() or target.read_bytes() != proposed.read_bytes():
            mismatches.append(row["targetPath"])
    if mismatches:
        raise base.ContractError("proposal is not implemented: " + ", ".join(mismatches))
    current = base.load_documents(root, Path("docs/architecture-workbench/current"))
    base.validate_documents(root, current)
    return {"proposalId": proposal.frontmatter["proposalId"], "implemented": True, "files": len(proposal.files)}


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("command", choices=("validate", "preview", "apply", "reconcile"))
    result.add_argument("--root", type=Path, default=Path.cwd())
    result.add_argument("--proposal", type=Path, required=True)
    result.add_argument("--approval", type=Path)
    return result


def main(arguments: Iterable[str] | None = None) -> int:
    options = parser().parse_args(arguments)
    root = options.root.resolve()
    try:
        proposal = parse_proposal((root / options.proposal).resolve(), root)
        current = base.load_documents(root, Path("docs/architecture-workbench/current"))
        if options.command == "apply":
            if options.approval is None:
                raise base.ContractError("apply requires --approval from explicit current-turn approval")
            result = apply_proposal(root, proposal, root / options.approval)
        elif options.command == "reconcile":
            result = reconcile_proposal(root, proposal)
        else:
            result = diff_proposal(current, proposal)
    except (base.ContractError, OSError, ValueError, json.JSONDecodeError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        return 1
    print(json.dumps({"status": "ok", **result}, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
