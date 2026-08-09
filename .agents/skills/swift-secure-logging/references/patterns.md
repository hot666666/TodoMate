# Swift Secure Logging Patterns

## Contents

- Package Shape
- Package Manifest
- Levels and Categories
- Shared Emission Path
- Release Behavior
- Sensitive Values
- Consumer Integration
- Call Sites
- Validation

## Package Shape

Put the common behavior in one local package when several consumers need it:

```text
localPackages/ProductLogger/
├── Package.swift
├── Sources/ProductLogger/
│   ├── ProductLog.swift
│   ├── LogCategory.swift
│   └── LogSanitizer.swift       # only when the product needs it
└── Tests/ProductLoggerTests/
    └── ProductLoggerTests.swift
```

If the repository already owns cross-cutting utilities in a foundation package, keep logging there instead of adding a dependency that breaks the existing ownership direction.

## Package Manifest

Match the repository's tools version and deployment targets:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProductLogger",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "ProductLogger", targets: ["ProductLogger"])
    ],
    targets: [
        .target(name: "ProductLogger"),
        .testTarget(name: "ProductLoggerTests", dependencies: ["ProductLogger"])
    ]
)
```

Do not raise deployment targets only to introduce the logger.

## Levels and Categories

Keep severity and domain as different dimensions:

```swift
public enum LogLevel: Int, Sendable {
    case debug
    case info
    case warning
    case error
    case fault
}

public enum LogCategory: String, CaseIterable, Sendable {
    case general
    case networking
    case persistence
    case security
    case sync
    case media
}
```

Choose categories from the product's actual domains. Avoid one category per file, and avoid sending most calls to `general`.

Expose one facade:

```swift
public enum ProductLog {
    public static func debug(
        _ message: @autoclosure () -> String,
        category: LogCategory = .general,
        fileID: StaticString = #fileID,
        line: UInt = #line
    ) {
        emit(
            level: .debug,
            message: message,
            category: category,
            fileID: fileID,
            line: line
        )
    }
}
```

Implement matching `info`, `warning`, `error`, and `fault` methods. Forward the message closure without calling it.

## Shared Emission Path

Route every public method through one private choke point:

```swift
private static func emit(
    level: LogLevel,
    message: () -> String,
    category: LogCategory,
    fileID: StaticString,
    line: UInt
) {
    #if DEBUG
    guard configuration.shouldLog(level) else { return }

    let rendered = "[\(fileID):\(line)] \(message())"
    sink.write(rendered, level: level, category: category)
    #endif
}
```

The sink maps levels and categories to the platform backend:

```swift
import OSLog

private static let networkLog = Logger(
    subsystem: "com.example.product",
    category: LogCategory.networking.rawValue
)

networkLog.info("\(message, privacy: .public)")
```

Use one cached `Logger` per category. Replace the sample subsystem with the product's reverse-DNS identifier.

## Release Behavior

For a privacy-first application, keep `#if DEBUG` at the top of the shared `emit` function as shown above. It must appear before:

- message autoclosure evaluation;
- source formatting;
- sanitization;
- OSLog or other sink calls.

Call sites do not need their own `#if DEBUG`. In Release, the facade forwards an unevaluated closure into an empty emission path and the optimizer can remove the no-op call.

If the product must retain production diagnostics, remove the all-or-nothing gate and set an explicit Release threshold such as `warning`. Document and test that alternative; do not leave the policy implicit.

Verify that custom build configurations define `DEBUG` only where intended.

## Sensitive Values

Do not build a universal sanitizer. Identify the few sensitive formats the product may log and implement only those rules. Sanitization is a safety net; credentials, keys, message content, and raw payloads should not be interpolated at all.

Example: redact a labeled credential.

```swift
enum LogSanitizer {
    static func sanitize(_ input: String) -> String {
        let credential = #/(?i)\b(password|token)\b\s*[:=]\s*[^\s,]+/#
        return input.replacing(credential) { match in
            "\(match.1)=<redacted>"
        }
    }
}
```

Example: shorten a diagnostic identifier at the call site.

```swift
let shortID = requestID.prefix(8)
ProductLog.debug("Request started id=\(shortID)…", category: .networking)
```

Adapt these examples to the project's actual identifiers and privacy requirements. Test one sensitive match, one safe non-match, and any format variation the product really emits.

When a sanitizer is needed, apply it to `rendered` inside the guarded shared emission path immediately before `sink.write`. Keep the message lazy until that point.

## Consumer Integration

Add the local package and product to every consuming Swift package:

```swift
dependencies: [
    .package(path: "../ProductLogger")
],
targets: [
    .target(
        name: "FeatureKit",
        dependencies: [
            .product(name: "ProductLogger", package: "ProductLogger")
        ]
    )
]
```

For an Xcode target, add the local package and link `ProductLogger`. Repeat this for app extensions, widgets, and test targets that import it.

## Call Sites

Use level for severity and category for domain:

```swift
ProductLog.debug("Sync pending=\(pending.count)", category: .sync)
ProductLog.info("Database migration completed", category: .persistence)
ProductLog.warning("Request retry scheduled", category: .networking)
ProductLog.error("Cache write failed code=\(errorCode)", category: .persistence)
```

Prefer states, counts, durations, and bounded error codes. Avoid full model descriptions, user content, raw `Error` descriptions, URLs with query data, and cryptographic material.

## Validation

Test the core contract:

- level ordering and threshold behavior;
- filtered messages are not evaluated;
- configured Debug and Release policy;
- any project-specific sanitizer rule;
- package integration in affected consumers.

Audit for bypasses:

```bash
rg -n --glob '*.swift' '\b(print|debugPrint|NSLog|os_log)\s*\(' Sources App Packages
rg -n --glob '*.swift' '\bLogger\s*\(' Sources App Packages
rg -n --glob '*.swift' 'ProductLog\.(debug|info|warning|error|fault)' Sources App Packages
```

Run the repository's established commands. A typical sequence is:

```bash
swift test --package-path localPackages/ProductLogger
xcodebuild -scheme Product -configuration Debug build
xcodebuild -scheme Product -configuration Release build
```

Treat package tests, app builds, and actual Console inspection as separate evidence.
