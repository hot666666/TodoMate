---
description: GitHub Pull Request Workflow - create PR to BASE_BRANCH
---

| Parameter      | Default | Description                             |
| -------------- | ------- | --------------------------------------- |
| `BASE_BRANCH`  | `dev`   | The target branch for the Pull Request. |
| `ISSUE_NUMBER` | -       | The related Issue number (if any).      |

# GitHub Pull Request Workflow

This workflow covers creating a Pull Request

## 1. Push & Create PR

- Push the working branch to the remote repository.
- Open a Pull Request (PR) targeting `BASE_BRANCH` (default: `dev`).
  - This can be done using the **GitHub CLI (`gh`)** or **GitHub MCP**.

PR body should follow the repository template:

- `.github/PR_TEMPLATE.md`

Also, link the PR to a GitHub Issue by including a closing keyword in the PR description (if possible):

```md
Fixes #<issue-number>
```

### Option A: Using GitHub MCP

- Use GitHub MCP to open a PR targeting `BASE_BRANCH`.
- When drafting the PR description/body, copy the structure from `.github/PR_TEMPLATE.md` and fill it in.

### Option B: Using GitHub CLI (`gh`)

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

# 3. Create PR using the body file(don't include $tmpfile in commit, it is just temporary file to be removed)
gh pr create --base <BASE_BRANCH> --title "feat: description" --body-file "$tmpfile"

# 4. Delete the temporary file
rm -f "$tmpfile"
```
