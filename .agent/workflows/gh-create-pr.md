---
description: Complete Pull Request workflow - from branch creation to merge, with guidelines for high-quality code reviews
---

# GitHub Pull Request Workflow

## Overview
Workflow for creating a Pull Request to BASE_BRANCH.

---

## 1. Prepare Changes
Ensure your code is clean, tests pass, and you are ready to request a review.

## 2. Commit Changes
Commit your code changes with a clear and descriptive message.

```bash
git add .
git commit -m "feat: description of changes"
```

## 3. Push Branch
Push your feature branch to the remote repository.

```bash
git push origin <feature-branch-name>
```

## 4. Create Pull Request

Use the `gh` CLI to create a high-quality PR.

### PR Title Guidelines
- Use conventional commit format: `feat:`, `fix:`, `refactor:`, `docs:`, etc.
- Be specific and descriptive
- Example: `feat: add user authentication flow`

### PR Body Best Practices

Create a comprehensive PR description using `pr_body.md`:

```markdown
## 📋 Summary
Brief overview of what this PR accomplishes.

## 🎯 Motivation
Why is this change needed? What problem does it solve?

## 🔧 Changes
- List key changes made
- Highlight important implementation details
- Note any breaking changes

## 🧪 Testing
- Describe how you tested these changes
- List test cases covered
- Include screenshots/recordings for UI changes (if applicable)

## 📝 Checklist
- [ ] Code follows project style guidelines
- [ ] Tests added/updated and passing
- [ ] Documentation updated (if needed)
- [ ] No breaking changes (or documented if unavoidable)

## 🔗 Related Issues
Closes #issue-number
```

### Create the PR

```bash
gh pr create --base <BASE_BRANCH> --head <feature-branch-name> --title "PR Title" --body-file pr_body.md
rm pr_body.md  # Cleanup the body file
```

**Tips:**
- Link related issues using `Closes #123` or `Fixes #456`
- Add reviewers: `gh pr create --reviewer username1,username2`
- Add labels: `gh pr create --label enhancement,documentation`
- Request reviews from teams: `gh pr create --reviewer team-name`

## 5. Review Process
Reviewers will examine the code for:
- Code quality and adherence to standards
- Logic correctness and potential bugs
- Test coverage
- Documentation completeness
- Performance implications

Be responsive to feedback and make requested changes promptly.

## 6. Merge Strategy

### When Using Squash Merge

If your team uses squash merge, all commits will be combined into a single commit on the base branch. Write a clear squash commit message that summarizes the entire PR.

### When Using Regular Merge

Keep your commit history clean with meaningful, atomic commits. Consider interactive rebase if needed to clean up the history before merging.

## 7. Post-Merge
Delete the feature branch.

---

## Additional Tips

### Writing Quality Commits
- Use present tense: "add feature" not "added feature"
- Keep first line under 50 characters
- Add detailed description after blank line if needed
- Reference issues: "fixes #123" or "relates to #456"

### PR Size Best Practices
- Keep PRs focused and small (ideally < 400 lines)
- Split large changes into multiple PRs
- Each PR should address one concern

### Collaboration
- Respond to comments constructively
- Use "Resolve conversation" when feedback is addressed
- Request re-review after significant changes
- Be open to alternative approaches
