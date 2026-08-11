# Architecture Markdown contract

## Contents

1. Document set
2. Frontmatter
3. Nodes
4. Relationships
5. Hierarchy
6. Traces
7. Unresolved facts
8. Evidence and commit drift
9. Generated projections

## Document set

Place current facts in `docs/architecture-workbench/current/`. A repository normally uses:

- `modules.md`
- `dependencies.md`
- `architecture.md`
- `ui-hierarchy.md`
- `state-hierarchy.md`
- `data-flows.md`

Files may be split differently when a repository needs it. Stable IDs are global across all current documents.

## Frontmatter

Every file starts with exactly one YAML-like frontmatter block:

```yaml
---
schemaVersion: 1
documentId: current.modules
modelLayer: modules
verifiedGitCommit: 0123456789abcdef0123456789abcdef01234567
status: current
---
```

Required fields:

| field | contract |
| --- | --- |
| `schemaVersion` | `1` |
| `documentId` | globally unique document identity |
| `modelLayer` | explorer grouping such as `modules`, `architecture`, `ui`, `state`, or `flows` |
| `verifiedGitCommit` | 40-character commit whose source evidence was inspected |
| `status` | `current` for observed documents; proposals use a separate contract |

`verifiedGitCommit` may be an ancestor of the document commit. Validation fails when cited source paths changed after that commit, avoiding a self-referential commit hash while still detecting source/document drift.

## Nodes

Put nodes below `# Nodes`. Each `##` heading is the stable ID and must match `[a-z0-9][a-z0-9._-]*`.

```markdown
# Nodes

## app.host

- kind: build-unit
- summary: Native application composition root.
- parent: repository.root
- module: AppHost
- status: observed
- confidence: high
- source: App/Package.swift#name: "AppHost"; App/Sources/AppMain.swift#struct AppMain
```

All seven fields are required. Use `parent: -` only for a root node. `status` is a semantic label such as `observed`, `legacy-dormant`, or `unresolved`. Confidence is `high`, `medium`, or `low`.

Distinguish node kinds that have different ownership: `repository`, `build-unit`, `module`, `source-folder`, `ide-group`, `logical-layer`, `screen`, `view`, `state-owner`, `data-store`, `service`, and `external-dependency` are common examples.

## Relationships

Use exactly this table below `# Relationships`:

```markdown
| sourceId | kind | targetId | status | confidence | evidence |
| --- | --- | --- | --- | --- | --- |
| app.host | depends-on | domain.core | observed | high | App/Package.swift#dependencies |
```

Both endpoint IDs must exist. Evidence is mandatory. Direction describes the source's action on the target.

## Hierarchy

Use exactly this table below `# Hierarchy`:

```markdown
| parentId | childId | relationship | condition | evidence |
| --- | --- | --- | --- | --- |
| app.window | app.sidebar | composes | always | App/Sources/MainView.swift#NavigationSplitView |
```

Both IDs must exist. Use `condition: always` when unconditional. Do not encode hierarchy only through graph layout.

## Traces

Use exactly this table below `# Traces`:

```markdown
| order | elementId | input | state change | effect/dependency | output | evidence |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | ui.create | tap | draft becomes submitting | invokes application client | command | App/Sources/CreateFeature.swift#case .createTapped |
```

Orders must be positive integers. Each trace is a contiguous table; use a `## trace.<stable-id>` heading before it. Every element ID must resolve to a node and every step needs evidence.

## Unresolved facts

Put uncertain or unverified statements below `# Unresolved`:

```markdown
| elementId | reason | verificationSuggestion | evidence |
| --- | --- | --- | --- |
| sync.boundary | Runtime adapter is not wired in the current host. | Inspect the next integration branch. | App/Sources/AppMain.swift#composition |
```

Do not promote an unresolved statement to an observed node or relationship. Evidence identifies why the uncertainty exists; the suggestion says how to resolve it.

## Evidence and commit drift

Evidence uses repository-relative `path#symbol` references. The path must exist and the exact symbol text must occur in the file. Separate multiple references with semicolons. Absolute paths and `..` traversal are invalid.

Validation checks:

- required frontmatter and fields
- duplicate stable IDs and document IDs
- dangling relationship endpoints
- invalid node parents and hierarchy endpoints
- missing evidence
- stale/missing source paths or symbols
- cited source files changed after `verifiedGitCommit`

The validator checks references and drift; an agent remains responsible for the architecture meaning.

## Generated projections

`resolved.generated.json` and `site/index.html` are derived only from Markdown. They must be reproducible after deletion and must never become an architecture authoring surface.
