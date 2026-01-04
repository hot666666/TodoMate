---
description: GitHub Pull Request Workflow - create PR to BASE_BRANCH with Screenshots for UI Verification
---

# GitHub Pull Request Workflow

## 1. Prepare Changes
Ensure your code is clean, tests pass, and you are ready to request a review.

## 2. Generate UI Screenshots (If UI changed)
Run the UI verification test to generate latest screenshots.
```bash
just test-ui-screenshots
```

## 3. Commit Changes & Screenshots
Commit your code changes AND the generated screenshots.
**Note:** Screenshots are tracked in the feature branch to allow visual review in the PR.
```bash
git add .
git commit -m "feat: description of changes"
```

## 4. Push Branch
Push your feature branch to the remote repository.
```bash
git push origin <feature-branch-name>
```

## 5. Create Pull Request
Use the `gh` CLI to create the PR.
```bash
gh pr create --base <BASE_BRANCH> --head <feature-branch-name> --title "PR Title" --body-file pr_body.md
```
*   `BASE_BRANCH` is typically `main` or `develop`.

## 6. Review Process
Reviewers will check the code and the `screenshots/` directory in the PR "Files changed" tab to verify UI correctness.

## 7. Merge Strategy (IMPORTANT)
**Before Squash Merging to Main:**
To prevent bloating the main repository history with binary screenshot files, you MUST remove them from the final commit that lands on main.

Since we use **Squash Merge**:
1.  Add a final commit to your branch that deletes the screenshots.
    ```bash
    git rm -r screenshots/
    git commit -m "chore: remove screenshots before merge"
    git push
    ```
2.  Perform the Squash Merge.
    *   The squash process combines all branch commits (adding screenshots + removing screenshots) into a single commit on main.
    *   The net result is that `screenshots/` files will **NOT** exist in the final squash commit on main, keeping the history clean.

## 8. Post-Merge
Delete the feature branch.
