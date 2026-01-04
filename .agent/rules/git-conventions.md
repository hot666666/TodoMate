---
trigger: always_on
description: Apply this rule when generating Git commit messages, handling Git hooks, or resolving Git lock issues.
---

# Git & Commit Conventions

## 1. Commit Message Structure
The basic structure consists of a **`Header`** and a **`Body`**, separated by a blank line.

```
type: title

body
```

### Header (Type & Title)
- **Format**: `type: title`
- **Constraint**: Title must not exceed 50 characters. No periods (.) or special characters at the end.

#### Types(Prefer Korean Description!, not type)
| Type | Description |
| --- | --- |
| **feat** | New feature |
| **fix** | Bug fix |
| **docs** | Documentation changes |
| **style** | Code formatting, missing semicolons, etc. (no code change) |
| **refactor** | Code refactoring |
| **test** | Adding tests or refactoring test code |
| **chore** | Build tasks, package manager config, etc. |

### Body
- Wrap lines at 72 characters.
- Explain **What** changed and **Why** in concise.

## 2. Pre-commit Hooks Warning
- **Warning**: This project uses pre-commit hooks (e.g., SwiftFormat, SwiftLint).
- **Scenario**: If a hook modifies a file (e.g., formatting), the file becomes **UNSTAGED**, causing the commit to fail.
- **Action**: Re-stage (`git add`) the modified files and retry the commit.
  - If "Files were modified by this hook" error occurs → `git add .` (or specific files) → Retry `git commit`.

## 3. Git Lock Issues
- **Scenario**: `.git/index.lock` might remain after a crash or interruption, blocking git commands.
- **Action**: Run `rm -f .git/index.lock` and retry.
