# Agent Guide for TodoMate

> **Note**: For core coding rules (Swift, SwiftUI, Project Structure), refer to `.agent/rules/project-rules.md`.

## Agent Workflow & Task Lifecycle
To ensure consistent contribution, follow this lifecycle for every task:

1.  **Start Task**: Use the `/feature` workflow or manually create a branch:
    ```bash
    git checkout -b feat/<task-name>
    ```
2.  **Implementation**:
    - Make changes.
    - Build frequently: `just build`.
3.  **Verification**:
    - Run tests: `just test`.
    - Ensure logical commits.
4.  **Completion**:
    - Notify the user that the branch is ready for review (PR).

## Development Workflow
- **Build/Test**: Use `just build` / `just test`.
- **Project File**: `TodoMate.xcodeproj` (Scheme: `TodoMate`).
- **Dependencies**: Ensure new targets integrate cleanly.

## Testing Expectations
- **Initial Phase**: Add unit tests in `TodoMateTests/` alongside changes.
- **Modularization**: As we move to SPM, write tests inside the modules.
- **Reporting**: Summarize test results in the walkthrough.

## Contribution Standards
- **Commits**: One logical change per commit. Sign if possible.
- **Simplicity**: Code must be human-readable.
- **Agent Requirements**: Prioritize simplicity and distinct, standalone commits.

## Deliverables & Documentation

### 1. PR Description
When notifying the user of completion, provide a PR description following this format:
- **Title**: `[Type] Title` (e.g., `[Feat] Implement Study Session`)
- **Summary**: 1-2 sentences on the *business value* or *technical goal*.
- **Key Changes**:
    - High-level architectural decisions.
    - Important specific implementation details.
- **Verification**: Brief confirmation of what was tested (e.g., "Unit tests passed, Manually verified flow X").

### 2. Walkthrough Artifact
- **File**: `walkthrough.md` (Update if exists, create if new).
- **Purpose**: A persistent record of *what* was done and *why*.
- **Structure**: Append a new H2 section matching the **PR Title**.
    - `## [Type] Title`
- **Content**:
    - **Context**: The problem/task.
    - **Changes**: Technical implementation details and lessons learned.
    - **Verification**: Test results, screenshots (if UI), or logs.
