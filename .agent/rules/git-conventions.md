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

# Merge Strategy & Merge Commit Rules
Default Merge Strategy

Default behavior: Use --no-ff merge unless explicitly instructed otherwise.

This ensures merge commits are always distinguishable from linear commits and preserve branch context.

Fast-forward merges are allowed only when explicitly requested.

Merge Commit Creation

All merges using --no-ff must result in a merge commit.

Do not squash unless explicitly instructed.

Merge Commit Message Guidelines

Merge commit messages must summarize the core intent and outcome of the merged branch.

The message should:

Focus on high-level changes and goals

Exclude excessive implementation details

Omit minor refactors or low-impact changes unless critical

Merge Commit Message Structure
merge: <source-branch> into <target-branch>

- Summarize major features or fixes introduced
- Highlight important architectural or behavioral changes
- Prefer message in Korean!

**Example**
```
merge: feature/study-session into main

- Introduced study session flow and persistence
- Integrated review scheduling logic
- Improved state synchronization in SwiftUI views
```

## Merge Preparation Rules

### 1. Branch Synchronization (Required)
- Before any merge, ensure **all related branches are up to date**.
- Always fetch the latest remote state first:
- The base branch (e.g. `main`, `develop`) must be at its latest commit before merging.

### 2. Rebase onto Base Branch
- Before merging, the feature branch must be **rebased onto the latest base branch**.
- This keeps history clean and minimizes merge conflicts.

### 3. Rebase Safety Rules
- Rebase only **private or unmerged feature branches**.
- Do NOT rebase:
- Branches already merged
- Branches shared with others
- Branches containing merge commits

### 4. After Rebase
- Resolve conflicts carefully without changing original intent.
- Run tests to ensure behavior is unchanged.
