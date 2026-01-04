---
description: PR Review Follow-up Workflow - handle AI review comments (gemini-assistant/copilot), update PR, prepare squash message, merge, and pull latest base branch.
---

| Parameter     | Default | Description                                           |
| ------------- | ------- | ----------------------------------------------------- |
| `BASE_BRANCH` | `dev`   | The target branch of the PR (and the branch to pull). |
| `PR_NUMBER`   | -       | The PR number to inspect/update (recommended to set). |

> **Note**: This workflow is used _after_ a PR is opened. It focuses on incorporating review feedback and finalizing a squash merge.

# PR Review Follow-up Workflow

This workflow is for **processing review feedback**. It does **not** cover merging.

## 1. Wait For / Fetch Review Feedback

AI reviewers (e.g., `gemini-assistant`, Copilot) may leave review comments after some time.

### Option A: Using GitHub MCP

- Open the PR via GitHub MCP.
- Check **Review comments** and **Conversation** timeline.

### Option B: Using GitHub CLI (`gh`)

```bash
# View PR details and latest comments
# If PR_NUMBER is unknown, use: gh pr list

gh pr view <PR_NUMBER> --comments
```

## 2. If There Is No Review Feedback

If there are no review comments available, **stop the workflow here** and inform the user.

Suggested message to the user:

```
리뷰 없음
```

## 3. Resolve Review Feedback (Commit Per Item)

If there are review comments/items, resolve them one by one:

- For each review item:
  - Make the requested change.
  - Run verification (prefer targeted tests first).
  - Commit the change.
  - Push to the PR branch.

```bash
# Repeat this cycle per review item

just build
just test-only <TestTarget>

git add -A
git commit -m "fix: address review feedback (<short topic>)"
git push origin <feature-branch>
```

After pushing, re-check the PR conversation/comments.

- If feedback still exists: repeat.
- If feedback no longer exists: stop and reply to the user:

```
존재하는 리뷰 없음
```
