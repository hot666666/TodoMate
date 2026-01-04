---
description: Development Workflow - create branches and tests (TDD) for the project, outlining the Red-Green-Refactor cycle and verification steps.
---

| Parameter     | Default | Description                                               |
| ------------- | ------- | --------------------------------------------------------- |
| `BASE_BRANCH` | (current branch) | The branch from which to create a new feature/fix branch. |
| `USE_PR`      | `false` | Whether to use GitHub PR workflow for merging.            |

> **Note**: If you need to work from a different base branch, specify it explicitly (e.g., `BASE_BRANCH=main`). Otherwise, the workflow assumes the **current working branch** as the default.

# Development Workflow

This project defines a strict **Red-Green-Refactor** cycle for all tasks. Agents must follow this workflow to ensure code quality, maintainability, and test coverage.

## Prerequisites

- **Configuration**: Check `GEMINI.md` for the current **Target Platform** and **Test Device**.
- **Rules**: Review `.agent/rules/project-rules.md` for Swift/SwiftUI coding standards.

## Branching Strategy

- All work must start by creating a new branch from `BASE_BRANCH` (default: current working branch).
- **Naming**: Use prefixes like `feat/X`, `fix/X`, `refactor/X` or `chore/X`.
- When merging back to `BASE_BRANCH`, a **Squash Merge** must be performed to maintain a clean history.

## 0. Test Authoring

### Clarifying the Given-When-Then Pattern

Each test must clearly distinguish between the following three stages:

- **Given**: Define initial values and expected results required for the test.
- **When**: Execute the actual action.
- **Then**: Verify the results.

### Defining Test Values at the Top

Declare the values to be used and verified at the beginning of the test:
(same when using Swift Testing)

```swift
func testExample() {
  // MARK: - Given
  let cardFrontOld = "elephant"
  let cardFrontNew = "modified_elephant"
  let targetDeck = "New Deck"

  // MARK: - When
  navigateToDeck(named: targetDeck)
  openCardEditSheet(for: cardFrontOld)
  ...

  // MARK: - Then
  XCTAssert(app.staticTexts[cardFrontNew].exists)
}

```

### Streamlining Verification Logic

- Use variables defined at the top instead of hardcoded strings.
- Make it clear which specific values are being checked during the verification stage.

## Workflow Cycle

### 1. Red: Write a Failing Test

- **Goal**: Define the expected behavior before implementing it.
- **Action**:
- Create or modify a unit test in the `AmgiTests` target.
- Use `XCTest` / `Swift Testing` to assert expected outcomes.
- Ensure the test fails (either does not compile or assertion fails).

- **Tip**: Naming conventions for tests should clearly state the scenario and expected result.

### 2. Green: Make it Pass

- **Goal**: Pass the test with the minimal amount of code.
- **Action**:
- Write just enough code in the application targets to satisfy the test.
- Focus on functionality, not perfection.
- **Do not** over-engineer at this stage.

### 3. Refactor: Improve Code

- **Goal**: Improve code structure while keeping tests green.
- **Action**:
- Remove code duplication.
- Optimization and cleanup.
- **Crucial**: Verify against `.agent/rules/project-rules.md` (e.g., proper `@Observable` usage, modern Swift concurrency).

- **Verification**: Run tests frequently to ensure no regression.

### 4. Verification

- **Goal**: Confirm the solution works in the target environment.
- **Impact-Based Testing (Targeted)**:
- To maintain development speed, prioritize running tests related to the modified components.
- Use the following command to run specific test classes or methods(with xcodebuild ... `-only-testing:`)

- **Full Verification**:
- Run the full test suite before finalizing the branch:

```bash
just test

```

- **Environment Check**:
- Ensure you are validating against the **Minimum Version** and **Test Device** specified in `GEMINI.md`.
- If UI tests are involved, ensure the simulator matches the `GEMINI.md` configuration.

## Commit & Merge

### Option A: Local Squash Merge (`USE_PR=false`)

Perform a local squash merge directly without creating a PR.

```bash
# 1. Checkout BASE_BRANCH
git checkout <BASE_BRANCH>

# 2. Squash merge the branch(replace <feature-branch> with your branch name)
git merge --squash <feature-branch>

# 3. Commit with a proper message (preferably in Korean)
git commit

# Example commit message (squash = summarize multiple commits into one)
#
# feat: 그룹 피드 로딩 안정화 및 동기화 개선
#
# What
# - GroupFeed 로딩 시 중복 요청 제거 및 상태 전이 정리
# - SyncManager 에러 처리 일원화(재시도/로그)
# - InviteCodeGenerator 단위 테스트 보강(경계값 포함)
#
# Why
# - 네트워크/동기화 실패 시 UI가 불안정하게 보이는 문제 완화
# - 추후 기능 추가 시 회귀를 막기 위해 핵심 유틸 테스트 강화

# 4. Push to remote
git push origin <BASE_BRANCH>

# 5. Delete the feature branch
git branch -d <feature-branch>
```

#### Local Squash Commit Message Guidelines

- **Remove**: Trivial, redundant, or low-signal commit messages.
- **Retain**: Only the essential and meaningful changes.
- **Format**: Be concise but explicit about _what_ and _why_.
- **Language**: Preferably written in **Korean**.

### Option B: GitHub PR Workflow (`USE_PR=true`)

Follow the **GitHub Pull Request Workflow** for code review and remote squash merge.

→ See: `.agent/workflows/github-pr-workflow.md`

```bash
# 1. Push the working branch
git push origin <feature-branch>

# 2. Follow github-pr-workflow.md for PR creation, review, and merge
```
