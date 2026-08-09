---
name: xcuitest-page-object-patterns
description: Apply reusable XCUITest page object, selector, accessibility identifier, and screenshot capture patterns. Use when adding, refactoring, or reviewing UI tests that need PageScreen/POM objects, selector sets, stable accessibility identifiers, screenshot recording separated from page objects, project-local wait helpers, screenshot-friendly screen wrappers, or readable end-to-end test flows.
metadata:
  short-description: Page object and selector UI test patterns
---

# XCUITest Page Object Patterns

## Workflow

1. Inspect the app UI code first and add stable `accessibilityIdentifier` values for UI elements that tests must find. Prefer centralized identifiers over inline strings.
2. Add or update a selector set for the screen or feature. Define a protocol for mockability, a concrete struct, private `IDs`, `Selector` values, metadata descriptions, groups, and `all`.
3. Add or update a `PageScreens/*Screen.swift` object. Store `XCUIApplication` and selector set dependencies. Expose private computed `XCUIElement` properties and public intent-level methods.
4. Keep screenshot capture in test support/base test utilities, not inside page objects. Page objects should only stabilize or expose the screen state that the test captures.
5. Keep tests readable by calling page methods such as `tapSaveButton()`, `assertToolbarVisible()`, or `navigateToURL(_)` instead of repeating raw element queries.
6. Use project-local wait helpers or `XCUIElement` extensions before tapping/asserting. Avoid arbitrary sleeps unless the existing framework has no reliable signal.
7. Model repeated screen transitions as page object methods that wait for the resulting state and return the next page object.
8. Update UI tests when new UI states need coverage, and update page objects/selectors when app accessibility identifiers change.

## Implementation Rules

- Prefer identifier-based selectors over label-based selectors. Use labels only for web content, system UI, or localized text cases where no app identifier exists.
- Put selector resolution in `Selector` and selector shortcut helpers, not in tests.
- Keep `PageScreen` methods domain-level and concise. They may return `XCUIElement` only when the test genuinely needs it, such as screenshots or drag/drop.
- Keep assertions inside page objects when they describe screen state; keep scenario sequencing inside test methods.
- Keep each screen object focused on one screen/surface. Create separate screen objects for alerts, sheets, menus, and major subflows when interactions grow.
- Make selector protocols injectable so tests can use alternate selectors or mocks.
- Keep screenshot output policy in one recorder: env-gated capture, deterministic output path, sanitized file names, and `XCTAttachment` creation.

## Reference

Read `references/patterns.md` when implementing a concrete UI test change. It includes compact templates for accessibility identifiers, selectors, page screens, tests, and screenshot recording.
