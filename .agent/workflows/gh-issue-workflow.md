---
description: GitHub Issue Workflow - use Issues to plan work, split into sub-issues, track progress, and integrate with PRs (MCP or CLI).
---

| Parameter | Default | Description                                                 |
| --------- | ------- | ----------------------------------------------------------- |
| `USE_MCP` | `true`  | Whether to prefer GitHub MCP over CLI for issue operations. |

# GitHub Issue Workflow

This workflow standardizes how we create and manage work using GitHub Issues (including sub-issues).

## 1. Create an Issue (Use a Template)

Use one of the repository templates:

- `.github/ISSUE_TEMPLATE/깃헙-이슈-템플릿.md`

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

## 2. Split Work Into Sub-Issues (Tasklist)

Why:

- Better history of decisions
- Parallelizable work
- Cleaner PRs

How:

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

## 3. Execute Work & Keep Records

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
