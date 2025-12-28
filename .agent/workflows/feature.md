---
description: Standard workflow for implementing a new feature or fix.
---

# Feature Implementation Workflow

Use this workflow when starting a new task or feature request.

> [!IMPORTANT]
> **작업 시작 전 반드시 브랜치를 먼저 생성할 것!**
> 코드 작성 전에 Step 1을 수행해야 함.

## 1. Create Branch (MUST - 작업 전 필수)

```bash
# Replace <feature-name> with the task name (kebab-case)
# 예: offline-first-sync, auth-manager, user-model
git checkout -b feat/<feature-name>
```
// turbo

## 2. Develop & Build

- Implement changes.
- Run build frequently:
  ```bash
  just build
  ```

## 3. Verify

- Run tests:
  ```bash
  just test
  ```

## 4. Documentation

- Create/Update `walkthrough.md`.
- **Important**: Use the PR Title as the H2 header (e.g., `## [Feat] ...`).
- Content:
  - Context
  - Key Changes
  - Verification Results (Log snippets, Screenshots)

## 5. Prepare for Review

- Commit changes:
  ```bash
  git add .
  git commit -m "feat: <description>"
  ```
- Notify user with "Senior-Level PR Description" as defined in `Agents.md`.

## 6. Push & Create PR

```bash
# Push to remote
git push -u origin HEAD
```
// turbo

- Create Pull Request via GitHub CLI:
  ```bash
  # -w flag opens browser for PR creation
  gh pr create -w
  ```
  또는 수동으로 GitHub 웹에서 PR 생성.

> [!TIP]
> PR 제목 형식: `[Feat] <간결한 설명>` (예: `[Feat] Offline-First Sync Infrastructure`)
