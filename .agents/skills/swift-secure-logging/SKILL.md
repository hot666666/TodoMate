---
name: swift-secure-logging
description: Build, refactor, or review a shared Swift logging system provided as a local SPM package. Use when work involves a common Logger or OSLog facade, log levels, domain categories, Debug versus Release behavior, sensitive-value sanitization, replacing print calls, package integration, or logger tests.
---

# Swift Secure Logging

## Workflow

1. Inspect existing logging calls, package manifests, Xcode targets, build configurations, and tests. Extend a compatible logger instead of creating a competing abstraction.
2. Create a small local Swift package when multiple app targets or packages need the same logging behavior. Export one logging product and keep OSLog details inside it.
3. Expose one public facade with ordered levels such as `debug`, `info`, `warning`, `error`, and optionally `fault`.
4. Define a small set of product-domain categories such as networking, persistence, security, sync, or media. Categorize by investigation domain, not source filename.
5. Route every public level method through one private emission function. Check the level before evaluating the message.
6. Decide the Release policy explicitly. When Release must perform no logging work, place `#if DEBUG` at the shared emission point before message evaluation, formatting, sanitization, and backend calls.
7. Add a small project-specific sanitizer only for sensitive values the product may interpolate. Prefer omitting secrets entirely; use redaction or shortened identifiers only where diagnostic correlation is necessary.
8. Add the logging product to every consuming package and Xcode target. Feature code should import the shared module instead of calling `print`, `Logger`, or `os_log` directly.
9. Test the logger package, then build or test affected consumers. Report package tests, app builds, and runtime Console inspection as separate evidence.

## Core Rules

- Keep one shared SPM product and one public logging facade.
- Keep levels and categories separate: level expresses severity; category expresses domain.
- Use `@autoclosure` or a lazy message closure and preserve laziness until the emission guard.
- Use one stable product subsystem and a bounded category set.
- Keep the Release policy visible in the shared emission function.
- Do not construct typed-event strings or `Error` descriptions before the Release and level guards.
- Never log passwords, tokens, keys, raw messages, attachments, or decrypted payloads, including in Debug.
- If sensitive identifiers are useful for correlation, create a product-specific sanitizer and test its exact transformations.
- Preserve the repository's dependency direction, deployment targets, naming, and unrelated worktree changes.

## Level Guidance

- `debug`: high-volume development diagnostics.
- `info`: meaningful successful transitions.
- `warning`: rejected input, degraded operation, retry, or recoverable failure.
- `error`: failed operations that require investigation.
- `fault`: severe invariant or system failure, only when the product needs a distinct level.

## Validation

1. Run the logging package tests.
2. Verify filtered messages are not evaluated.
3. Test any sanitizer with representative sensitive and safe values.
4. Build an affected consumer in Debug and Release configurations.
5. Search production sources for direct logging bypasses.
6. If runtime visibility matters, inspect actual Console output separately.

## Reference

Read `references/patterns.md` before implementing a concrete logger. It contains the SPM layout, level/category facade, shared emission gate, Release handling, compact sanitizer examples, consumer integration, and tests.
