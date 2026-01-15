---
description: This project ensures code stability and quality by adhering to Test-Driven Development. Implementations must be validated through tests to verify correctness, prevent regression bugs, and maintain refactoring safety.
---

# Development Workflow

## Pre-flight Check (Required)

Before starting any work, always verify the following:

```bash
git status
git log --oneline -5
````

1. Confirm whether the current branch has already been merged.
2. If the branch is already completed/merged and the user has not explicitly requested rework, **do not proceed with any work and exit immediately**.

---

## Parameters

| Parameter     | Default        | Description |
|---------------|----------------|-------------|
| `BASE_BRANCH` | Current branch | Base branch for new feat/fix branches (e.g. `BASE_BRANCH=dev`) |
| `USE_PR`      | `false`        | Enable GitHub PR workflow (`.agent/workflows/gh-create-pr.md`) |

---

## Prerequisites

1. Check execution environment requirements such as **Target Platform / Test Device / Minimum Version** in `GEMINI.md`.
2. Review `.agent/rules/project-rules.md` and comply with the **Swift/SwiftUI coding rules**.

---

## Branching Strategy

1. All work must start from a new branch created off `BASE_BRANCH`.
2. Branch naming conventions (refer to existing naming patterns):

   * `feat/<topic>` — New features
   * `fix/<topic>` — Bug fixes
   * `refactor/<topic>` — Code refactoring
   * `chore/<topic>` — Build, configuration, or other maintenance tasks

---

## Core Development Principle: Think Verification First

**Before starting implementation, first think about how it will be verified.**

If the user does not provide explicit verification methods or test scope, ask:

* How can we confirm that this feature works correctly?
* What outputs are expected for given inputs?
* Under which conditions should it fail?

Define the answers to these questions upfront as **test code** or **clear verification procedures**.

### Test Writing Guidelines

* Clearly express the **Given-When-Then** structure
* Declare expected values (strings/IDs/dates) as variables at the top of the test and reuse them
* Prefer **Swift Testing** for new unit tests
* Use **XCTest** for UI automation or performance tests
* Additional UI test guidance: `docs/xctest-ui-test.md`

> **Tip**: Reviewing existing tests is the fastest way to understand the project’s testing patterns.

---

## TDD Workflow: Red-Green-Refactor

### 1) Red: Write a Failing Test

First, lock in the expected behavior as a test.

* Logic/models/services → **Unit Test**
* UI-level behavior → **UI Test**
* Confirm that the test fails (compile error or assertion failure)

### 2) Green: Make It Pass with the Minimum Implementation

Add only the **minimum code required** to pass the test.

* No over-engineering, no future-proofing
* Keep the change scope small
* Commit in small increments after confirming tests pass

### 3) Refactor: Improve Structure

Improve code quality while keeping all tests passing.

* Remove duplication, improve readability
* Follow rules defined in `.agent/rules/project-rules.md`

---

## Definition of Done

Criteria for considering work complete:

* [ ] Requirements are covered by tests or reproducible verification steps
* [ ] Failure cases are considered (errors/empty states/permissions/network, etc.)
* [ ] All affected tests pass successfully

### Verification Source of Truth (Priority Order)

Verification criteria should be identified in the following priority order:

1. Workflow documents in this repository
2. Acceptance criteria from related issues/PRs
3. Attached test plans or checklists

> **If explicit verification methods are defined, they take absolute priority** (do not change without owner approval).

---

## Workflow Summary

1. **Check and create branch**

   * Understand the current state via pre-flight checks
   * Create a new branch with appropriate naming

2. **Plan verification first**

   * If no explicit verification is given, decide how to verify
   * Prefer automated tests when possible

3. **Plan implementation**

   * Break work into small, incremental steps

4. **Iterate Red-Green-Refactor**

   * Write tests → implement → refactor
   * Commit frequently in small units

5. **Final verification**

   * Confirm Definition of Done is satisfied
   * Run all relevant tests for impacted areas

---

## GitHub PR Workflow (USE_PR=true)

When `USE_PR=true`, follow the PR workflow.

**Detailed guide**: `.agent/workflows/gh-create-pr.md`

```bash
git push origin <feature-branch>
# Create PR → Review → Remote squash merge
```

---

## Related Skills

* **Pre-commit Hooks**: `.agent/skills/pre-commit-hooks.md`
* **Testing Commands**: Refer to `justfile` (build, test, test-unit, test-ui, etc.)
