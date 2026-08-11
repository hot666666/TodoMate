# Architecture feedback contract

Feedback is a review artifact that points at canonical Architecture Markdown. It never authorizes source-code changes by itself.

## Request envelope

The HTML exporter and loopback server use exactly these JSON fields:

| field | contract |
| --- | --- |
| `targetId` | stable node ID or stable trace ID from current Markdown |
| `targetDocumentId` | current document that owns the target |
| `verifiedGitCommit` | commit shown when the request was authored |
| `category` | `question`, `factual-error`, `missing`, `wrong-relationship`, `improvement`, or `code-change-request` |
| `request` | user question or requested improvement, 1–4000 characters |
| `context` | optional relationship or trace context, at most 1000 characters |

The static explorer downloads this envelope as JSON. When served by the bundled loopback server, the same envelope may be posted to the fixed `/api/feedback` endpoint.

## Canonical feedback Markdown

Accepted requests are stored under `docs/architecture-workbench/feedback/open/` using a server-generated ID and this form:

```markdown
---
schemaVersion: 1
feedbackId: feedback-20260811t120000-a1b2c3d4
targetId: app.host
targetDocumentId: current.architecture
verifiedGitCommit: 0123456789abcdef0123456789abcdef01234567
category: question
status: open
createdAt: 2026-08-11T03:00:00Z
---

# Request

Which component owns this dependency?

# Context

Selected relationship: app.host depends-on domain.core

# Agent Responses

| respondedAt | disposition | confidence | answer | evidence | unresolvedReason |
| --- | --- | --- | --- | --- | --- |
```

Allowed statuses are `open`, `needs-review`, `answered`, `correction-proposed`, and `resolved`. A request whose `verifiedGitCommit` no longer matches its target document is rendered as `needs-review`, even if its stored status predates that drift.

Response dispositions are `answer`, `correction-proposed`, `needs-review`, and `resolved`. Confidence is `high`, `medium`, or `low`. An answer or correction must cite repository-relative `path#symbol` evidence. Use `unresolvedReason` when evidence is insufficient.

For a factual error, change `current/*.md` and rebuild generated projections; never patch generated JSON or HTML. A `code-change-request` remains a request until the user approves a separate proposed/apply workflow.

## Loopback server boundary

The server:

- binds only to `127.0.0.1`;
- serves only the generated index, `/api/health`, and `POST /api/feedback`;
- accepts same-loopback Host/Origin values, JSON only, and at most 64 KiB;
- validates target identity against current Markdown;
- generates the file name itself and uses exclusive creation;
- writes only inside the configured feedback directory;
- exposes no command execution, source-write, arbitrary path, LLM, credential, or remote-upload endpoint.
