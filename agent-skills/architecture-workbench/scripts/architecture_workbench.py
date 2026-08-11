#!/usr/bin/env python3
"""Validate canonical architecture Markdown and build disposable projections."""

from __future__ import annotations

import argparse
import html
import json
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable


SCHEMA_VERSION = "1"
FRONTMATTER_FIELDS = {
    "schemaVersion",
    "documentId",
    "modelLayer",
    "verifiedGitCommit",
    "status",
}
NODE_FIELDS = {"kind", "summary", "parent", "module", "status", "confidence", "source"}
STABLE_ID = re.compile(r"^[a-z0-9][a-z0-9._-]*$")
COMMIT = re.compile(r"^[0-9a-f]{40}$")
FIELD_LINE = re.compile(r"^- ([A-Za-z]+):\s*(.*)$")


class ContractError(Exception):
    pass


@dataclass
class Document:
    path: Path
    frontmatter: dict[str, str]
    nodes: list[dict[str, Any]] = field(default_factory=list)
    relationships: list[dict[str, Any]] = field(default_factory=list)
    hierarchy: list[dict[str, Any]] = field(default_factory=list)
    traces: list[dict[str, Any]] = field(default_factory=list)
    unresolved: list[dict[str, Any]] = field(default_factory=list)


def parse_frontmatter(text: str, path: Path) -> tuple[dict[str, str], list[str]]:
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        raise ContractError(f"{path}: missing opening frontmatter delimiter")
    try:
        end = lines.index("---", 1)
    except ValueError as error:
        raise ContractError(f"{path}: missing closing frontmatter delimiter") from error

    values: dict[str, str] = {}
    for number, line in enumerate(lines[1:end], start=2):
        if not line.strip():
            continue
        if ":" not in line:
            raise ContractError(f"{path}:{number}: invalid frontmatter line")
        key, value = line.split(":", 1)
        key, value = key.strip(), value.strip().strip('"')
        if key in values:
            raise ContractError(f"{path}:{number}: duplicate frontmatter field {key}")
        values[key] = value
    return values, lines[end + 1 :]


def table_rows(lines: list[str], path: Path, section: str) -> list[dict[str, str]]:
    rows = [line for line in lines if line.strip().startswith("|")]
    if not rows:
        return []

    def cells(line: str) -> list[str]:
        return [cell.strip() for cell in line.strip().strip("|").split("|")]

    headers = cells(rows[0])
    if len(rows) == 1:
        return []
    separator = cells(rows[1])
    if len(separator) != len(headers) or not all(re.fullmatch(r":?-{3,}:?", cell) for cell in separator):
        raise ContractError(f"{path}: {section} table is missing a Markdown separator row")
    parsed: list[dict[str, str]] = []
    for row_number, row in enumerate(rows[2:], start=3):
        values = cells(row)
        if len(values) != len(headers):
            raise ContractError(f"{path}: {section} table row {row_number} has the wrong column count")
        parsed.append(dict(zip(headers, values)))
    return parsed


def parse_document(path: Path) -> Document:
    frontmatter, lines = parse_frontmatter(path.read_text(encoding="utf-8"), path)
    document = Document(path=path, frontmatter=frontmatter)
    section = ""
    section_lines: dict[str, list[str]] = {"Relationships": [], "Hierarchy": [], "Unresolved": []}
    node: dict[str, Any] | None = None
    trace_id: str | None = None
    trace_lines: list[str] = []

    def finish_node() -> None:
        nonlocal node
        if node is not None:
            document.nodes.append(node)
            node = None

    def finish_trace() -> None:
        nonlocal trace_id, trace_lines
        if trace_id is not None:
            for row in table_rows(trace_lines, path, f"trace {trace_id}"):
                row["traceId"] = trace_id
                document.traces.append(row)
        trace_id = None
        trace_lines = []

    for line in lines:
        if line.startswith("# ") and not line.startswith("## "):
            finish_node()
            finish_trace()
            section = line[2:].strip()
            continue
        if line.startswith("## "):
            if section == "Nodes":
                finish_node()
                node = {"id": line[3:].strip()}
            elif section == "Traces":
                finish_trace()
                trace_id = line[3:].strip()
            continue
        if section == "Nodes" and node is not None:
            match = FIELD_LINE.match(line.strip())
            if match:
                node[match.group(1)] = match.group(2).strip()
        elif section in section_lines:
            section_lines[section].append(line)
        elif section == "Traces" and trace_id is not None:
            trace_lines.append(line)

    finish_node()
    finish_trace()
    document.relationships = table_rows(section_lines["Relationships"], path, "Relationships")
    document.hierarchy = table_rows(section_lines["Hierarchy"], path, "Hierarchy")
    document.unresolved = table_rows(section_lines["Unresolved"], path, "Unresolved")

    document_id = frontmatter.get("documentId", "")
    model_layer = frontmatter.get("modelLayer", "")
    for collection in (
        document.nodes,
        document.relationships,
        document.hierarchy,
        document.traces,
        document.unresolved,
    ):
        for item in collection:
            item["documentId"] = document_id
            item["modelLayer"] = model_layer
    return document


def split_references(value: str) -> list[tuple[str, str]]:
    references: list[tuple[str, str]] = []
    for raw in value.split(";"):
        raw = raw.strip()
        if not raw or raw == "-":
            continue
        if "#" not in raw:
            raise ContractError(f"source reference must use path#symbol: {raw}")
        path, symbol = raw.split("#", 1)
        references.append((path.strip(), symbol.strip()))
    return references


def run_git(root: Path, arguments: list[str], check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *arguments],
        cwd=root,
        check=check,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def require_columns(
    rows: list[dict[str, Any]], required: set[str], path: Path, section: str, errors: list[str]
) -> None:
    for index, row in enumerate(rows, start=1):
        missing = sorted(required - row.keys())
        if missing:
            errors.append(f"{path}: {section} row {index} missing columns: {', '.join(missing)}")


def validate_documents(root: Path, documents: list[Document]) -> dict[str, Any]:
    errors: list[str] = []
    document_ids: set[str] = set()
    nodes: dict[str, dict[str, Any]] = {}
    referenced_paths_by_commit: dict[str, set[str]] = {}

    for document in documents:
        path = document.path.relative_to(root)
        missing_frontmatter = sorted(FRONTMATTER_FIELDS - document.frontmatter.keys())
        extra_frontmatter = sorted(document.frontmatter.keys() - FRONTMATTER_FIELDS)
        if missing_frontmatter:
            errors.append(f"{path}: missing frontmatter fields: {', '.join(missing_frontmatter)}")
        if extra_frontmatter:
            errors.append(f"{path}: unsupported frontmatter fields: {', '.join(extra_frontmatter)}")
        if document.frontmatter.get("schemaVersion") != SCHEMA_VERSION:
            errors.append(f"{path}: schemaVersion must be {SCHEMA_VERSION}")
        if document.frontmatter.get("status") != "current":
            errors.append(f"{path}: current document status must be current")
        document_id = document.frontmatter.get("documentId", "")
        if document_id in document_ids:
            errors.append(f"{path}: duplicate documentId {document_id}")
        document_ids.add(document_id)
        commit = document.frontmatter.get("verifiedGitCommit", "")
        if not COMMIT.fullmatch(commit):
            errors.append(f"{path}: verifiedGitCommit must be a 40-character lowercase SHA")
        else:
            referenced_paths_by_commit.setdefault(commit, set())

        require_columns(
            document.relationships,
            {"sourceId", "kind", "targetId", "status", "confidence", "evidence"},
            path,
            "Relationships",
            errors,
        )
        require_columns(
            document.hierarchy,
            {"parentId", "childId", "relationship", "condition", "evidence"},
            path,
            "Hierarchy",
            errors,
        )
        require_columns(
            document.traces,
            {"order", "elementId", "input", "state change", "effect/dependency", "output", "evidence"},
            path,
            "Traces",
            errors,
        )
        require_columns(
            document.unresolved,
            {"elementId", "reason", "verificationSuggestion", "evidence"},
            path,
            "Unresolved",
            errors,
        )

        for node in document.nodes:
            node_id = node.get("id", "")
            if not STABLE_ID.fullmatch(node_id):
                errors.append(f"{path}: invalid stable node ID {node_id!r}")
            if node_id in nodes:
                errors.append(f"{path}: duplicate stable node ID {node_id}")
            nodes[node_id] = node
            missing = sorted(NODE_FIELDS - node.keys())
            if missing:
                errors.append(f"{path}: node {node_id} missing fields: {', '.join(missing)}")
            if node.get("confidence") not in {"high", "medium", "low"}:
                errors.append(f"{path}: node {node_id} has invalid confidence")
            if not node.get("source") or node.get("source") == "-":
                errors.append(f"{path}: node {node_id} is missing source evidence")

    for document in documents:
        relative_document_path = document.path.relative_to(root)
        commit = document.frontmatter.get("verifiedGitCommit", "")
        evidence_values: list[tuple[str, str]] = []
        evidence_values.extend((node.get("id", "node"), node.get("source", "")) for node in document.nodes)
        for section_name, collection in (
            ("relationship", document.relationships),
            ("hierarchy", document.hierarchy),
            ("trace", document.traces),
            ("unresolved", document.unresolved),
        ):
            evidence_values.extend((section_name, row.get("evidence", "")) for row in collection)

        for owner, evidence in evidence_values:
            if not evidence:
                errors.append(f"{relative_document_path}: {owner} is missing evidence")
                continue
            try:
                references = split_references(evidence)
            except ContractError as error:
                errors.append(f"{relative_document_path}: {owner}: {error}")
                continue
            if not references:
                errors.append(f"{relative_document_path}: {owner} is missing source evidence")
            for source_path, symbol in references:
                candidate = Path(source_path)
                if candidate.is_absolute() or ".." in candidate.parts:
                    errors.append(f"{relative_document_path}: unsafe source path {source_path}")
                    continue
                absolute = root / candidate
                if not absolute.is_file():
                    errors.append(f"{relative_document_path}: stale source path {source_path}")
                    continue
                if not symbol:
                    errors.append(f"{relative_document_path}: empty source symbol for {source_path}")
                    continue
                try:
                    source_text = absolute.read_text(encoding="utf-8")
                except UnicodeDecodeError:
                    errors.append(f"{relative_document_path}: source is not UTF-8 text: {source_path}")
                    continue
                if symbol not in source_text:
                    errors.append(
                        f"{relative_document_path}: stale source symbol {source_path}#{symbol}"
                    )
                if COMMIT.fullmatch(commit):
                    referenced_paths_by_commit.setdefault(commit, set()).add(source_path)

    for node_id, node in nodes.items():
        parent = node.get("parent", "-")
        if parent != "-" and parent not in nodes:
            errors.append(f"node {node_id}: invalid parent {parent}")

    for document in documents:
        path = document.path.relative_to(root)
        for row in document.relationships:
            for key in ("sourceId", "targetId"):
                if row.get(key) not in nodes:
                    errors.append(f"{path}: dangling relationship {key} {row.get(key)}")
        for row in document.hierarchy:
            for key in ("parentId", "childId"):
                if row.get(key) not in nodes:
                    errors.append(f"{path}: invalid hierarchy {key} {row.get(key)}")
        for row in document.traces:
            if row.get("elementId") not in nodes:
                errors.append(f"{path}: trace references missing element {row.get('elementId')}")
            try:
                if int(row.get("order", "0")) < 1:
                    raise ValueError
            except ValueError:
                errors.append(f"{path}: trace order must be a positive integer")
        for row in document.unresolved:
            if row.get("elementId") not in nodes:
                errors.append(f"{path}: unresolved row references missing element {row.get('elementId')}")

    for commit, source_paths in referenced_paths_by_commit.items():
        if not COMMIT.fullmatch(commit):
            continue
        exists = run_git(root, ["cat-file", "-e", f"{commit}^{{commit}}"], check=False)
        if exists.returncode != 0:
            errors.append(f"verifiedGitCommit does not exist: {commit}")
            continue
        ancestor = run_git(root, ["merge-base", "--is-ancestor", commit, "HEAD"], check=False)
        if ancestor.returncode != 0:
            errors.append(f"verifiedGitCommit is not an ancestor of HEAD: {commit}")
            continue
        if source_paths:
            ordered_paths = sorted(source_paths)
            committed = run_git(root, ["diff", "--name-only", f"{commit}..HEAD", "--", *ordered_paths])
            working = run_git(root, ["diff", "--name-only", "HEAD", "--", *ordered_paths])
            changed = sorted(set(committed.stdout.splitlines() + working.stdout.splitlines()))
            if changed:
                errors.append(
                    f"source evidence changed after {commit[:12]}: {', '.join(changed)}"
                )

    if errors:
        raise ContractError("\n".join(errors))
    return {
        "documents": len(documents),
        "nodes": len(nodes),
        "relationships": sum(len(document.relationships) for document in documents),
        "hierarchy": sum(len(document.hierarchy) for document in documents),
        "traces": len({row["traceId"] for document in documents for row in document.traces}),
        "unresolved": sum(len(document.unresolved) for document in documents),
    }


def resolved_model(documents: list[Document]) -> dict[str, Any]:
    return {
        "schemaVersion": SCHEMA_VERSION,
        "documents": [
            {
                "documentId": document.frontmatter["documentId"],
                "modelLayer": document.frontmatter["modelLayer"],
                "verifiedGitCommit": document.frontmatter["verifiedGitCommit"],
                "status": document.frontmatter["status"],
                "source": document.path.name,
            }
            for document in documents
        ],
        "nodes": [node for document in documents for node in document.nodes],
        "relationships": [row for document in documents for row in document.relationships],
        "hierarchy": [row for document in documents for row in document.hierarchy],
        "traces": [row for document in documents for row in document.traces],
        "unresolved": [row for document in documents for row in document.unresolved],
    }


def render_html(model: dict[str, Any]) -> str:
    model_json = json.dumps(model, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    title = html.escape("Architecture Workbench")
    template = r'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>__TITLE__</title>
<style>
:root{color-scheme:dark;--bg:#0b1020;--panel:#121a2d;--line:#2a3856;--text:#edf3ff;--muted:#9aa9c5;--accent:#65d6c4;--warn:#f4be62}*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:14px/1.45 system-ui,sans-serif}button,input,select{font:inherit}.top{position:sticky;top:0;z-index:5;display:grid;grid-template-columns:auto 1fr repeat(3,minmax(130px,190px));gap:10px;align-items:center;padding:12px 16px;background:#0d1426eF;border-bottom:1px solid var(--line);backdrop-filter:blur(12px)}h1{font-size:17px;margin:0}.top input,.top select{width:100%;padding:8px 10px;color:var(--text);background:var(--panel);border:1px solid var(--line);border-radius:8px}.layout{display:grid;grid-template-columns:minmax(0,1fr) 330px;min-height:calc(100vh - 61px)}main{padding:16px;overflow:auto}.tabs{display:flex;gap:8px;margin-bottom:12px}.tabs button,.pill,button{color:var(--text);background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:7px 10px;cursor:pointer}.tabs button[aria-selected=true]{border-color:var(--accent);color:var(--accent)}.view{display:none}.view.active{display:block}.graph-wrap{position:relative;min-height:620px;border:1px solid var(--line);border-radius:12px;background:radial-gradient(circle at 20% 10%,#162540,#0c1324 65%);overflow:auto}.graph{position:relative;display:grid;grid-template-columns:repeat(auto-fill,minmax(210px,1fr));gap:18px;padding:28px;z-index:2}.edges{position:absolute;inset:0;width:100%;height:100%;pointer-events:none;z-index:1}.edge{stroke:#52709b;stroke-width:1.5;opacity:.55}.node{position:relative;min-height:105px;padding:12px;border:1px solid #334668;border-radius:10px;background:#121b30;text-align:left}.node:hover,.node.selected{border-color:var(--accent);box-shadow:0 0 0 2px #65d6c422}.node.dim{opacity:.22}.node strong{display:block;color:#fff}.node small{display:block;color:var(--muted);margin:4px 0}.badge{display:inline-block;margin:5px 5px 0 0;padding:2px 6px;border-radius:999px;background:#223452;color:#bdd0ef;font-size:11px}.empty{padding:40px;color:var(--muted);text-align:center}.panel{border:1px solid var(--line);border-radius:10px;background:var(--panel);padding:14px;margin-bottom:12px}.panel h2,.panel h3{margin:0 0 8px;font-size:15px}.relations{display:grid;grid-template-columns:1fr 1fr;gap:10px}.relation{padding:9px;border-left:3px solid var(--accent);background:#0d1528}.tree ul{list-style:none;margin:5px 0 5px 18px;padding-left:12px;border-left:1px solid var(--line)}.tree button{padding:4px 7px}.trace-step{display:grid;grid-template-columns:32px 160px 1fr;gap:10px;padding:12px;border-bottom:1px solid var(--line)}.trace-step:last-child{border:0}.order{width:28px;height:28px;border-radius:50%;display:grid;place-items:center;background:var(--accent);color:#06201d;font-weight:700}aside{position:sticky;top:61px;height:calc(100vh - 61px);overflow:auto;border-left:1px solid var(--line);background:#0d1426;padding:16px}aside h2{margin:0 0 12px}dl{margin:0}dt{color:var(--muted);font-size:11px;text-transform:uppercase;margin-top:10px}dd{margin:2px 0;word-break:break-word}.source{font-family:ui-monospace,monospace;font-size:12px;color:#b7c8e8}.actions{display:flex;gap:8px;margin-top:12px}.count{color:var(--muted);font-size:12px}@media(max-width:900px){.top{grid-template-columns:1fr 1fr}.layout{grid-template-columns:1fr}aside{position:static;height:auto;border-left:0;border-top:1px solid var(--line)}}
</style>
</head>
<body>
<header class="top"><h1>Architecture Workbench</h1><input id="search" aria-label="Search" placeholder="Search IDs, summaries, modules"><select id="layer" aria-label="Model layer"></select><select id="kind" aria-label="Node kind"></select><select id="confidence" aria-label="Confidence"><option value="">All confidence</option><option>high</option><option>medium</option><option>low</option></select></header>
<div class="layout"><main><nav class="tabs" aria-label="Views"><button data-view="graph" aria-selected="true">Graph</button><button data-view="hierarchy">Hierarchy</button><button data-view="traces">Traces</button><span class="count" id="count"></span></nav><section id="graph" class="view active"><div class="graph-wrap"><svg class="edges" id="edges"></svg><div class="graph" id="nodes"></div></div></section><section id="hierarchy" class="view"><div class="panel tree" id="tree"></div></section><section id="traces" class="view"><div class="panel"><label>Trace <select id="traceSelect"></select></label></div><div class="panel" id="traceSteps"></div></section></main><aside><h2>Inspector</h2><div id="inspector" class="count">Select an element to inspect its source evidence and relationships.</div></aside></div>
<script id="architecture-model" type="application/json">__MODEL_JSON__</script>
<script>
(()=>{'use strict';const model=JSON.parse(document.getElementById('architecture-model').textContent);const byId=new Map(model.nodes.map(n=>[n.id,n]));const $=id=>document.getElementById(id);let selected=null;let neighborhood=new Set();const state={query:'',layer:'',kind:'',confidence:''};
const unique=(xs)=>[...new Set(xs)].sort();function options(select,values,label){select.innerHTML=`<option value="">${label}</option>`+values.map(v=>`<option>${escapeHTML(v)}</option>`).join('')};function escapeHTML(v){const d=document.createElement('div');d.textContent=v??'';return d.innerHTML}
options($('layer'),unique(model.documents.map(d=>d.modelLayer)),'All model layers');options($('kind'),unique(model.nodes.map(n=>n.kind)),'All kinds');
function layerNodes(layer){const ids=new Set(model.nodes.filter(n=>n.modelLayer===layer).map(n=>n.id));for(const e of model.relationships.filter(e=>e.modelLayer===layer)){ids.add(e.sourceId);ids.add(e.targetId)}for(const h of model.hierarchy.filter(h=>h.modelLayer===layer)){ids.add(h.parentId);ids.add(h.childId)}for(const s of model.traces.filter(s=>s.modelLayer===layer))ids.add(s.elementId);return ids}function visible(n){const q=state.query.toLowerCase(),allowed=state.layer?layerNodes(state.layer):null;return(!allowed||allowed.has(n.id))&&(!state.kind||n.kind===state.kind)&&(!state.confidence||n.confidence===state.confidence)&&(!q||[n.id,n.summary,n.module,n.kind].join(' ').toLowerCase().includes(q))}
function renderGraph(){const nodes=model.nodes.filter(visible);$('count').textContent=`${nodes.length} / ${model.nodes.length} nodes`;$('nodes').innerHTML=nodes.length?nodes.map(n=>`<button class="node${n.id===selected?' selected':''}${neighborhood.size&&!neighborhood.has(n.id)&&n.id!==selected?' dim':''}" data-id="${escapeHTML(n.id)}"><strong>${escapeHTML(n.id)}</strong><small>${escapeHTML(n.summary)}</small><span class="badge">${escapeHTML(n.kind)}</span><span class="badge">${escapeHTML(n.module)}</span></button>`).join(''):'<div class="empty">No matching nodes</div>';document.querySelectorAll('.node').forEach(b=>b.addEventListener('click',()=>selectNode(b.dataset.id)));requestAnimationFrame(drawEdges)}
function drawEdges(){const svg=$('edges'),wrap=svg.parentElement,base=wrap.getBoundingClientRect();svg.setAttribute('viewBox',`0 0 ${wrap.scrollWidth} ${wrap.scrollHeight}`);svg.innerHTML='';for(const e of model.relationships){const a=document.querySelector(`.node[data-id="${CSS.escape(e.sourceId)}"]`),b=document.querySelector(`.node[data-id="${CSS.escape(e.targetId)}"]`);if(!a||!b)continue;const ar=a.getBoundingClientRect(),br=b.getBoundingClientRect(),x1=ar.left-base.left+wrap.scrollLeft+ar.width/2,y1=ar.top-base.top+wrap.scrollTop+ar.height/2,x2=br.left-base.left+wrap.scrollLeft+br.width/2,y2=br.top-base.top+wrap.scrollTop+br.height/2;svg.insertAdjacentHTML('beforeend',`<line class="edge" x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}"/>`)}}
function related(id,direction){return model.relationships.filter(e=>direction==='up'?e.sourceId===id:e.targetId===id).map(e=>direction==='up'?e.targetId:e.sourceId)}function selectNode(id,push=true){selected=id;neighborhood=new Set([id,...related(id,'up'),...related(id,'down')]);const n=byId.get(id);if(!n)return;const outgoing=model.relationships.filter(e=>e.sourceId===id),incoming=model.relationships.filter(e=>e.targetId===id);$('inspector').innerHTML=`<dl><dt>ID</dt><dd>${escapeHTML(n.id)}</dd><dt>Summary</dt><dd>${escapeHTML(n.summary)}</dd><dt>Kind / module</dt><dd>${escapeHTML(n.kind)} · ${escapeHTML(n.module)}</dd><dt>Status / confidence</dt><dd>${escapeHTML(n.status)} · ${escapeHTML(n.confidence)}</dd><dt>Source evidence</dt><dd class="source">${escapeHTML(n.source).replaceAll(';',';<br>')}</dd></dl><div class="actions"><button id="upstream">Upstream ${outgoing.length}</button><button id="downstream">Downstream ${incoming.length}</button><button id="clear">Clear</button></div><h3>Relationships</h3><div>${[...outgoing,...incoming].map(e=>`<div class="relation"><b>${escapeHTML(e.sourceId)} ${escapeHTML(e.kind)} ${escapeHTML(e.targetId)}</b><div class="source">${escapeHTML(e.evidence)}</div></div>`).join('')||'<span class="count">None</span>'}</div>`;$('upstream').onclick=()=>highlight([id,...related(id,'up')]);$('downstream').onclick=()=>highlight([id,...related(id,'down')]);$('clear').onclick=()=>{selected=null;neighborhood.clear();$('inspector').textContent='Select an element to inspect its source evidence and relationships.';renderGraph()};if(push)history.replaceState(null,'',`#node=${encodeURIComponent(id)}`);renderGraph()}
function highlight(ids){state.query='';state.layer='';state.kind='';state.confidence='';$('search').value='';$('layer').value='';$('kind').value='';$('confidence').value='';neighborhood=new Set(ids);renderGraph()}
function renderTree(){const children=new Map();for(const h of model.hierarchy){if(!children.has(h.parentId))children.set(h.parentId,[]);children.get(h.parentId).push(h.childId)}const childIds=new Set(model.hierarchy.map(h=>h.childId));const roots=model.nodes.filter(n=>!childIds.has(n.id)&&children.has(n.id));const branch=(id,seen=new Set())=>{if(seen.has(id))return'';const next=new Set(seen).add(id),kids=(children.get(id)||[]).sort();return `<li><button data-tree-id="${escapeHTML(id)}">${escapeHTML(id)}</button>${kids.length?`<ul>${kids.map(k=>branch(k,next)).join('')}</ul>`:''}</li>`};$('tree').innerHTML=`<h2>Composition and ownership hierarchy</h2><ul>${roots.map(r=>branch(r.id)).join('')}</ul>`;document.querySelectorAll('[data-tree-id]').forEach(b=>b.onclick=()=>selectNode(b.dataset.treeId))}
function renderTrace(){const id=$('traceSelect').value,steps=model.traces.filter(s=>s.traceId===id).sort((a,b)=>Number(a.order)-Number(b.order));$('traceSteps').innerHTML=steps.map(s=>`<div class="trace-step"><span class="order">${escapeHTML(s.order)}</span><button data-trace-node="${escapeHTML(s.elementId)}">${escapeHTML(s.elementId)}</button><div><b>${escapeHTML(s.input)} → ${escapeHTML(s.output)}</b><div>${escapeHTML(s['state change'])}</div><div class="count">${escapeHTML(s['effect/dependency'])}</div><div class="source">${escapeHTML(s.evidence)}</div></div></div>`).join('')||'<div class="empty">No trace steps</div>';document.querySelectorAll('[data-trace-node]').forEach(b=>b.onclick=()=>selectNode(b.dataset.traceNode))}
const traceIds=unique(model.traces.map(s=>s.traceId));$('traceSelect').innerHTML=traceIds.map(id=>`<option>${escapeHTML(id)}</option>`).join('');$('traceSelect').onchange=renderTrace;renderTrace();renderTree();renderGraph();
for(const id of ['search','layer','kind','confidence'])$(id).addEventListener(id==='search'?'input':'change',e=>{state[id==='search'?'query':id]=e.target.value;renderGraph()});document.querySelectorAll('.tabs button').forEach(b=>b.onclick=()=>{document.querySelectorAll('.tabs button').forEach(x=>x.setAttribute('aria-selected',String(x===b)));document.querySelectorAll('.view').forEach(v=>v.classList.toggle('active',v.id===b.dataset.view))});addEventListener('resize',drawEdges);const initial=new URLSearchParams(location.hash.slice(1)).get('node');if(initial&&byId.has(initial))selectNode(initial,false)})();
</script>
</body></html>
'''
    return template.replace("__TITLE__", title).replace("__MODEL_JSON__", model_json)


def load_documents(root: Path, docs_directory: Path) -> list[Document]:
    absolute = root / docs_directory
    if not absolute.is_dir():
        raise ContractError(f"architecture Markdown directory not found: {docs_directory}")
    paths = sorted(absolute.glob("*.md"))
    if not paths:
        raise ContractError(f"no architecture Markdown found in {docs_directory}")
    return [parse_document(path) for path in paths]


def command_validate(root: Path, docs_directory: Path) -> dict[str, Any]:
    documents = load_documents(root, docs_directory)
    return validate_documents(root, documents)


def command_build(root: Path, docs_directory: Path, output_directory: Path) -> dict[str, Any]:
    documents = load_documents(root, docs_directory)
    summary = validate_documents(root, documents)
    model = resolved_model(documents)
    destination = root / output_directory
    site = destination / "site"
    site.mkdir(parents=True, exist_ok=True)
    (destination / "resolved.generated.json").write_text(
        json.dumps(model, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    (site / "index.html").write_text(render_html(model), encoding="utf-8")
    return {**summary, "outputs": [str(output_directory / "resolved.generated.json"), str(output_directory / "site/index.html")]}


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    subcommands = result.add_subparsers(dest="command", required=True)
    for name in ("validate", "build"):
        command = subcommands.add_parser(name)
        command.add_argument("--root", type=Path, default=Path.cwd())
        command.add_argument(
            "--docs", type=Path, default=Path("docs/architecture-workbench/current")
        )
        if name == "build":
            command.add_argument(
                "--output", type=Path, default=Path("docs/architecture-workbench")
            )
    return result


def main(arguments: Iterable[str] | None = None) -> int:
    options = parser().parse_args(arguments)
    root = options.root.resolve()
    try:
        if options.command == "validate":
            result = command_validate(root, options.docs)
        else:
            result = command_build(root, options.docs, options.output)
    except (ContractError, OSError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        return 1
    print(json.dumps({"status": "ok", **result}, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
