# Agent Guide for TodoMate

## Purpose

Agents act as senior Swift collaborators for TodoMate.
Keep responses concise, clarify uncertainty before coding, and align suggestions with the rules linked below.

## Rule Index

- **Project Rules**: `.agent/rules/project-rules.md` (Swift/SwiftUI Norms)
- **Git Conventions**: `.agent/rules/git-conventions.md` (Commit/Hook Rules)
- **Open Source**: `.agent/rules/opensource-usage.md` (External Code Access)

## Repository Overview

- **Product Context**: iOS/macOS App managing Todos with Groups, built with SwiftUI & SwiftData.
- **Architecture**: `[Fill in by LLM assistant]`
- **Codebase Map**:
  - `TodoMate/`: App Entry, Configuration.
  - `TodoMateTests/`: Unit Tests.
  - `Packages/`: `[Fill in by LLM assistant]`
  - `.agent/`: Brain (Rules, Workflows).

## Development Workflow (TDD)

Follow the **Red-Green-Refactor** cycle for every task.
Details: `.agent/workflows/development-workflow.md`

1.  **Red**: Write a failing test for the desired behavior.
2.  **Green**: Write the minimal code to pass the test.
3.  **Refactor**: Improve code structure while keeping tests green.
4.  **Verify**: `just build`, `just test` (Targeted).

## Technical Standards

- **Language**: Swift 6.2+
- **Concurrency**: Strict `Sendable` usage, `@MainActor` for UI.
- **UI**: SwiftUI (ViewComposer pattern), `@Observable` for data.
- **Environment**: `[Fill in by LLM assistant]`

## Commands

- **Build**: `just build`
- **Test**: `just test` (See `.agent/workflows/build-commands.md`)
- **Git**: See `.agent/rules/git-conventions.md`

## Special Notes

- Do not mutate files outside the workspace root without explicit approval.
- Commit only things you modified yourself.
- When unsure, **ASK** the user.

## UI Verification

For UI-related changes, verify results visually using screenshots captured during XCUITests.

### Capture Screenshots

Run the following command to execute UI tests and export screenshots:

```bash
just test-ui-screenshots
```

This will:
1. Run `TodoMateUITests/ScreenshotTests` (6 tests)
2. Export attachments from `TestResults.xcresult`
3. Rename files to human-readable names (e.g., `personal_board_0.png`)
4. Save all screenshots to `screenshots/` directory

### Screenshot Files

Screenshots are named based on `ScreenType` enum defined in `TodoMateUITests/ScreenType.swift`:
- `personal_board_0.png` - Personal Todo Board view
- `personal_calendar_0.png` - Personal Calendar view
- `group_feed_0.png` - Group Feed view
- `no_groups_view_0.png` - "No Groups Joined" empty state
- `add_task_overlay_0.png` - Add Task overlay
- `sidebar_open_0.png`, `sidebar_closed_0.png` - Sidebar toggle states
- `window_default_0.png` - Default window state

### Key Files

- `TodoMateUITests/ScreenType.swift` - Enum defining capturable screens
- `TodoMateUITests/ScreenNavigator.swift` - Navigation helper for tests
- `TodoMateUITests/ScreenshotCapture.swift` - Screenshot capture utility
- `TodoMateUITests/ScreenshotTests.swift` - UI screenshot tests
- `script/rename_screenshots.py` - Renames exported files to readable names

### Manual Export

To extract screenshots from an existing xcresult:

```bash
just export-screenshots <path-to-xcresult>
```

## Documentation & Resources

### Core Documentation

- **Architecture**: [docs/App/architecture.md]
- **MV Patterns**: [docs/mv-patterns.md]
- **Performance**: [docs/understanding-improving-swiftui-performance.md], [docs/optimizing-swiftui-performance-instruments.md]

### Workflows

- **Refactor SwiftUI Views**: `.agent/workflows/refactor-swiftui-views.md`
- **Performance Audit**: `.agent/workflows/performance-audit.md`
- **Development Workflow**: `.agent/workflows/development-workflow.md`
- **Build Commands**: `.agent/workflows/build-commands.md`
- **Github**: `.agent/workflows/github/*`

### Reference

- **All Rules**: `.agent/rules/`
