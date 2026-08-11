---
name: architecture-workbench
description: Maintain repository architecture as schema-backed Markdown and generate a validated offline JSON and interactive HTML explorer. Use when Codex or Claude must document, audit, explore, or update modules, dependencies, logical layers, UI/state hierarchy, or evidence-backed data flows alongside structural code changes.
---

# Architecture Workbench

Treat `docs/architecture-workbench/current/*.md` as the architecture source of truth. Treat the resolved JSON, graph layout, and HTML as disposable projections.

## Workflow

1. Read repository instructions, manifests, build metadata, current architecture documents, and the real producer-consumer source paths.
2. Read [references/markdown-contract.md](references/markdown-contract.md) before authoring or changing architecture Markdown.
3. Copy [assets/templates/architecture-document.md](assets/templates/architecture-document.md) when adding a document. Replace every placeholder; do not leave template IDs in project documents.
4. Record only observed current facts under `current/`. Put uncertainty in the Unresolved table with a reason and verification suggestion. Never write a planned architecture as observed.
5. Update source evidence at the same time as structural code changes. Scanner checks may detect drift, but must not invent architecture meaning.
6. Run:

   ```bash
   python3 agent-skills/architecture-workbench/scripts/architecture_workbench.py validate --root .
   python3 agent-skills/architecture-workbench/scripts/architecture_workbench.py build --root .
   ```

7. Inspect the generated offline HTML: switch model layers, search/filter, select a node, inspect source evidence, follow upstream/downstream relationships, expand hierarchy, open a trace, and confirm the browser console has no errors.
8. For questions or corrections, read [references/feedback-contract.md](references/feedback-contract.md). Static HTML exports a JSON request; the optional loopback server stores only validated feedback Markdown. Review source and current Markdown before writing an Agent response.
9. For a code-change request, read [references/proposal-contract.md](references/proposal-contract.md). Keep the To-Be snapshot under `proposed/`; preview As-Is/To-Be/Diff. Apply code and current Markdown together only after an exact current-turn approval matches the proposal digest and base commit, then reconcile.

## Authoring rules

- Use stable semantic IDs. Do not derive identity from display names, array positions, or graph layout.
- Keep build unit, module, source folder, and IDE group as distinct node kinds.
- Use semantic relationship kinds such as `depends-on`, `contains`, `observes`, `invokes`, or `persists`; avoid Boolean flags and generic `connected` edges.
- Separate framework-specific concepts. For example, use State/Action/Effect only where that framework is actually present; describe Observation stores with their real ownership model.
- Cite repository-relative source paths and exact symbol text as `path#symbol`. Separate multiple references with semicolons.
- Do not edit `resolved.generated.json` or `site/index.html` by hand.
- Feedback never authorizes production changes. Correct factual architecture errors in `current/*.md`; route code-change requests through the proposed/approval workflow.

## Adapters

- Codex: follow [adapters/codex.md](adapters/codex.md).
- Claude Code: follow [adapters/claude-code.md](adapters/claude-code.md).
