---
description: Strict workflow: Implement -> Target Test -> Commit -> Rebase -> PR (Template Required)
---

# Strict Feature Implementation Workflow

Follow this cycle precisely. Do NOT skip testing or committing in small steps.

## 1. Setup & Branching (Base: refactor)
- **Base Branch**: Checks out from `refactor` (unless specified otherwise).
- **Update Base**: Ensure base is up-to-date.
  ```bash
  git checkout refactor
  git pull origin refactor
  git checkout -b feat/<feature-name>
  ```
  // turbo

## 2. Implementation Loop (Repeat for each logical unit)

### A. Implement
- Write code for a specific, small unit.
- **Do not** implement the entire feature at once.

### B. Targeted Verify (CRITICAL)
- **Do NOT** run full tests (`just test`) initially.
- Run tests **ONLY** for the code you modified.
  ```bash
  # Example
  xcodebuild test -scheme TodoMate -destination 'platform=macOS' -only-testing:TodoMateTests/TodoManagerTests 2>&1 | xcbeautify
  ```
- If tests fail, **FIX** immediately.

### C. Atomic Commit
- Commit **only** what you verified.
  ```bash
  git add <specific-files>
  git commit -m "feat(scope): detailed message"
  ```
- **Note**: If pre-commit hooks modify files, re-add and commit.

## 3. Pre-PR Rebase (MANDATORY)
- **Requirement**: You MUST perform an interactive rebase onto `refactor` before PR.
- **Interaction**: Ask the user for permission/confirmation before running rebase.
  ```bash
  git fetch origin refactor
  git rebase -i origin/refactor
  ```

## 4. Pull Request (Template Required)
- **Documentation**: Update `walkthrough.md` first.
- **PR Format**: Use the following Markdown template in the PR body.

### PR Template

```markdown
## Summary
(Brief description of the feature/fix)

## Changes
| 파일 | 역할 |
|---|---|
| `User.swift` | (Description) |
| `Manager.swift` | (Description) |

## Key Design Decisions
1. (Decision 1)
2. (Decision 2)

## Verification
- [ ] just build 성공
- [ ] Unit Test passed
```

- **Command**:
  ```bash
  gh pr create --title "[Feat] <Title>" --body-file <path-to-body-file> --base refactor
  ```
  *(Tip: Write body to a temporary file first to ensure formatting)*

> [!IMPORTANT]
> **Rules**:
> 1. **Base Branch**: Always target `refactor` unless instructed otherwise.
> 2. **Feedback Loop**: Fix -> Test -> Commit. Do not batch everything.
> 3. **Rebase**: Always rebase before PR to keep history clean.
