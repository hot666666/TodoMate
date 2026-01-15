
---
name: pre-commit-hooks
description: Handles pre-commit hooks that automatically enforce code quality standards (SwiftFormat, SwiftLint) before commits
---

# Pre-commit Hooks Management

## WHAT THIS DOES

Handles pre-commit hooks that automatically enforce code quality standards before commits. This project uses SwiftFormat and SwiftLint to maintain consistent code style.

## WHEN TO USE

- When a commit fails due to pre-commit hook violations
- When files become UNSTAGED after automatic formatting
- When you need to manually fix formatting or linting issues

## HOW IT WORKS

### Pre-commit Hooks in This Project

1. **SwiftFormat**: Automatically formats code according to project rules
2. **SwiftLint**: Checks for code style violations

### Common Scenario: Hook Modifies Files

When pre-commit hooks auto-fix files, they become **UNSTAGED**:

```bash
# Re-stage the modified files
git add .

# Retry commit
git commit -m "your message"
```

### Manual Fix When Needed

If commits keep failing:

```bash
# Run SwiftFormat
swiftformat .

# Run SwiftLint with auto-fix
swiftlint --config .swiftlint.yml --fix

# Stage and commit
git add .
git commit -m "your message"
```

## CONFIGURATION

- **SwiftFormat**: `.swiftformat` file
- **SwiftLint**: `.swiftlint.yml` file

## TIPS

- Review auto-fixes with `git diff` before committing
- Following `.agent/rules/project-rules.md` minimizes hook failures
- Consistent failures may indicate deeper issues in config or code
