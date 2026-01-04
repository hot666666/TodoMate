---
description: GitHub Issue Workflow - plan work with Issues, split into independent/dependent items, then execute each item via development-workflow.
---

| Parameter     | Default | Description                                                 |
| ------------- | ------- | ----------------------------------------------------------- |
| `USE_MCP`     | `true`  | Whether to prefer GitHub MCP over CLI for issue operations. |
| `BASE_BRANCH` | `dev`   | Base branch used by the development workflow.               |
| `USE_PR`      | `true`  | Whether each work item is delivered via PR.                 |

# GitHub Issue Workflow

This workflow standardizes how we use GitHub Issues to **plan and execute work**.

Key idea:

- Use the **parent Issue** as the single source of truth.
- Split the work into **work items** (sub-issues or a task list).
- Execute each work item using `../development-workflow.md` (branch + TDD + verification + optional PR).

This is intentionally a “think first, split well, then execute” workflow.

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
- Cleaner PRs

How (rules of thumb):

- Prefer splitting into **independently shippable** items.
  - Examples: separate screens, isolated utilities, single manager changes, a single data model migration.
- If items have **dependencies**, make the order explicit and execute them **sequentially**.
  - Typical order: (1) data model → (2) manager/service → (3) UI → (4) tests/cleanup.
- Keep each item small enough to be completed via one `development-workflow` cycle.

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

## 3. Execute Each Item via `development-workflow.md`

For each work item (sub-issue or tasklist item), run a full development cycle using:

- `../development-workflow.md` (with `BASE_BRANCH` and `USE_PR` as needed)

Recommended loop per item:

1. Pick the next work item

- Prefer independent items first
- If dependent: only start when prerequisites are done

2. Create a branch, implement via TDD, and verify
3. Deliver via PR if `USE_PR=true` (recommended)
4. Close the sub-issue / tick the tasklist item
5. Leave a short comment on the parent issue (progress + next)

- Use the parent issue as the “single source of truth”.
- Post short progress updates as comments (what changed / what’s next / blockers).
- Prefer targeted tests during iteration:
  - `just test-only <TestTarget>`
  - `just test-only-many <T1> <T2>`
- Run `just test` only when needed (pre-merge / broad regression).

## 4. Open a PR Linked to the Issue

- In the PR description, follow `.github/PR_TEMPLATE.md`.
- Link the issue using GitHub closing keywords:

```md
Fixes #123
```

This enables automatic issue closing on merge.

## 5. Close Out

When the work is done:

- Ensure acceptance criteria are met.
- Ensure verification is documented (targeted tests + any full run if applicable).
- Close sub-issues (usually automatic via PR links, or manual if needed).
