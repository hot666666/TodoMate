---
description: GitHub Pull Request Workflow - create PR to BASE_BRANCH, code review, and squash merge guidelines.
---

| Parameter     | Default | Description                             |
| ------------- | ------- | --------------------------------------- |
| `BASE_BRANCH` | `dev`   | The target branch for the Pull Request. |

> **Note**: This workflow is invoked from `development-workflow.md` when `USE_PR=true`.

# GitHub Pull Request Workflow

This workflow covers creating a Pull Request, code review process, and squash merge guidelines.

## 1. Push & Create PR

- Push the working branch to the remote repository.
- Open a Pull Request (PR) targeting `BASE_BRANCH` (default: `dev`).
  - This can be done using the **GitHub CLI (`gh`)** or **GitHub MCP**.

PR body should follow the repository template:

- `.github/PR_TEMPLATE.md`

Also, link the PR to a GitHub Issue by including a closing keyword in the PR description (recommended):

```md
Fixes #<issue-number>
```

### Option A: Using GitHub CLI (`gh`)

```bash
# Example using GitHub CLI
gh pr create --base <BASE_BRANCH> --title "feat: description" --body "Details..."
```

If the PR body is non-trivial, prefer drafting it in a temporary file and passing it via `--body-file`:

```bash
# 1. Create a temporary file
tmpfile=$(mktemp)

# 2. Draft PR body into the file
# Tip: start from the repository template
cp .github/PR_TEMPLATE.md "$tmpfile"

# Optional: open the file in your editor to fill it in
# open -e "$tmpfile"

# 3. Create PR using the body file
gh pr create --base <BASE_BRANCH> --title "feat: description" --body-file "$tmpfile"

# 4. Delete the temporary file
rm -f "$tmpfile"
```

### Option B: Using GitHub MCP

- Use GitHub MCP to open a PR targeting `BASE_BRANCH`.
- When drafting the PR description/body, copy the structure from `.github/PR_TEMPLATE.md` and fill it in.

## 2. Code Review Process

- PR is automatically assigned to an AI-based reviewer (e.g., `gemini-assistant`).
  - Review may take some time, but not too long.
- The reviewer performs:
  - **Summary**: Summarize the intent and scope of the changes.
  - **Security Analysis**: Analyze potential vulnerabilities or risky patterns.
  - **Feedback**: Provide structural, performance, or readability feedback when applicable.
