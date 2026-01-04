---
description: Perform squash merge (MCP or gh), then pull base branch.
---

| Parameter     | Default | Description                                           |
| ------------- | ------- | ----------------------------------------------------- |
| `BASE_BRANCH` | `dev`   | The target branch of the PR (and the branch to pull). |
| `PR_NUMBER`   | -       | The PR number to update/merge.                        |

# Resolve PR Feedback & Merge Workflow

Use this workflow when **review feedback exists** and you need to resolve it, update the PR, and merge.

## 1. Resolve Feedback

- Address requested changes in code.
- Add/adjust tests if required.
- Re-run verification (prefer targeted tests first).
- Push updates to the same PR branch.

```bash
just build

# Prefer targeted tests related to your change
just test-only <TestTarget>

# Run full suite only when needed
# just test

git push origin <feature-branch>
```

(Optional) Post a short PR comment summarizing what changed.

## 2. Squash Merge The PR

### Option A: Merge via GitHub UI / MCP

- Ensure the PR is ready.
- Choose **Squash and merge**.
- Paste a good squash commit message (Korean preferred).

### Option B: Merge via GitHub CLI (`gh`)

```bash
gh pr merge <PR_NUMBER> --squash --delete-branch
```

## 3. Post-Merge: Update Local Base Branch

```bash
git checkout <BASE_BRANCH>
git pull origin <BASE_BRANCH>
```
