---
description: GitHub Issue Workflow - split a request into clear work items and create issues.
---

| Parameter | Default | Description                                                 |
| --------- | ------- | ----------------------------------------------------------- |
| `USE_MCP` | `true`  | Whether to prefer GitHub MCP over CLI for issue operations. |

# GitHub Issue Workflow

This workflow standardizes how we use GitHub Issues to **plan work**.

Key idea:

- Use the **parent Issue** as the single source of truth.
- Split the work into **work items** (sub-issues or a task list).

This is intentionally a “think first, split well” workflow.

## 0. Convert an Input Into Work Items

When you have a raw request (chat/message/spec), produce a small set of work items.

Rules of thumb:

- First, write the **one-sentence outcome** (what the user should be able to do).
- Then list 2–6 **work items** that each produce a visible result.
- If something is unclear, add a work item named **“Clarify requirements”** with concrete questions.
- For each work item, write **Acceptance Criteria** as checkboxes.
- Keep scope tight: avoid bundling “refactor + feature + polish” into one item.

Task list draft format (in the parent issue):

```md
- [ ] <Work item title> — <short outcome>
```

## 1. Create an Issue (Use a Template)

Use one of the repository templates:

- `.github/ISSUE_TEMPLATE/깃헙-이슈-템플릿.md`

(For bugs, use the bug template.)

Guidelines:

- Write a clear title with a prefix (e.g., `[Feat]`, `[Fix]`, `[Refactor]`, `[Test]`, `[Bug]`).
- Fill **Acceptance Criteria** so “done” is unambiguous.
- Add a minimal **Test Plan** (targeted tests first).

### Option A: Using GitHub MCP (`USE_MCP=true`)

- Create the issue in GitHub MCP.
- Apply labels/assignees as needed.
- Use comments for progress updates.

### Option B: Using GitHub CLI (`gh`)

```bash
# Create an issue (interactive editor opens)
gh issue create

# Or create with a title/body
gh issue create --title "[Feat] ..." --body "..."
```

## 2. Split Work Into Work Items (Sub-Issues / Tasklist)

Why:

- Better history of decisions
- Parallelizable work
- Clearer scope per item

How (rules of thumb):

- Prefer splitting into **independently shippable** items.
  - Examples: separate screens, isolated utilities, single manager changes, a single data model migration.
- If items have **dependencies**, make the order explicit and execute them **sequentially**.
  - Typical order: (1) data model → (2) manager/service → (3) UI → (4) tests/cleanup.
- Keep each item small enough to be reviewed and merged independently.

Output (what good looks like):

- Each work item should have: **Goal**, **Acceptance Criteria**, **Minimal Test Plan**.
- Prefer 1–3 acceptance criteria that are objectively checkable.
- Avoid vague tasks like “cleanup” unless you name what changes.

Tracking options:

- Create small sub-issues for concrete chunks of work.
- In the parent issue, track them with a task list referencing issue numbers:

```md
- [ ] #123
- [ ] #124
```

(Optional) In each sub-issue body, add a backlink:

```md
Related: #<parent>
```

## 3. Turn Work Items Into Issues

Choose one approach:

- **Sub-issues** (recommended when items are large or assigned to different people)
- **Task list in the parent issue** (recommended when items are small and owned by one person)

Suggested issue body template for each work item:

```md
## Goal

## Acceptance Criteria

- [ ]

## Notes (optional)
```

## 4. Keep the Parent Issue Up To Date

- Keep the parent issue as the source of truth (status + remaining work items)
- If scope changes, update the work items first, then continue
