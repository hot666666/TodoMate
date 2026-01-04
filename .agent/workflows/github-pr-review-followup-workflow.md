---
description: PR Review Follow-up Workflow - handle AI review comments (gemini-assistant/copilot), update PR, prepare squash message, merge, and pull latest base branch.
---

| Parameter     | Default | Description                                           |
| ------------- | ------- | ----------------------------------------------------- |
| `BASE_BRANCH` | `dev`   | The target branch of the PR (and the branch to pull). |
| `PR_NUMBER`   | -       | The PR number to inspect/update (recommended to set). |

> **Note**: This workflow is used _after_ a PR is opened. It focuses on incorporating review feedback and finalizing a squash merge.

# PR Review Follow-up Workflow

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

## 2. Apply Feedback (If Any)

If there are comments/review items:

- Address requested changes in code.
- Add/adjust tests if required.
- Re-run verification (`just build`, targeted tests).
- Push updates to the same PR branch.

```bash
# After changes are made
just build

# Prefer targeted tests related to your change (fast feedback)
# Example:
just test-only TodoMateTests/InviteCodeGeneratorTests

# Run full test suite only when needed
# just test

git push origin <feature-branch>
```

## 3. If There Is No Review Feedback Yet

If there are no review comments available yet, **stop the workflow here**.

- Inform the user that there is no review feedback yet.
- Wait and check again later.

Suggested message to the user:

```
아직 리뷰 코멘트가 없습니다. 조금 뒤 다시 확인해 주세요.
```

## 4. Squash Merge The PR

### Option A: Merge via GitHub UI / MCP

- Ensure the PR is ready.
- Choose **Squash and merge**.
- Paste a good squash commit message (Korean preferred).

### Option B: Merge via GitHub CLI (`gh`)

```bash
gh pr merge <PR_NUMBER> --squash --delete-branch
```

## 5. Post-Merge: Update Local Base Branch

After the PR is merged, update your local `BASE_BRANCH`:

```bash
git checkout <BASE_BRANCH>
git pull origin <BASE_BRANCH>
```
