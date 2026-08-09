# XCUITest Page Object Patterns

## Contents

- Accessibility Identifiers
- Selector Set
- Selector Model
- Page Screen
- Test Flow
- Screenshot Capture
- Waits And Assertions

## Accessibility Identifiers

Centralize app identifiers in a feature namespace:

```swift
struct AccessibilityIdentifiers {
    struct Feature {
        static let rootView = "Feature.RootView"
        static let titleLabel = "Feature.TitleLabel"
        static let primaryButton = "Feature.PrimaryButton"
    }
}
```

Apply identifiers in UIKit setup or component view models:

```swift
private lazy var titleLabel: UILabel = .build { label in
    label.accessibilityIdentifier = AccessibilityIdentifiers.Feature.titleLabel
}

let buttonViewModel = PrimaryRoundedButtonViewModel(
    title: .Feature.PrimaryButtonTitle,
    a11yIdentifier: AccessibilityIdentifiers.Feature.primaryButton
)
primaryButton.configure(viewModel: buttonViewModel)
```

## Selector Set

Use a protocol plus concrete selectors. This keeps page objects testable and makes selector changes local.

```swift
protocol FeatureSelectorsSet {
    var ROOT_VIEW: Selector { get }
    var TITLE_LABEL: Selector { get }
    var PRIMARY_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct FeatureSelectors: FeatureSelectorsSet {
    private enum IDs {
        static let rootView = AccessibilityIdentifiers.Feature.rootView
        static let titleLabel = AccessibilityIdentifiers.Feature.titleLabel
        static let primaryButton = AccessibilityIdentifiers.Feature.primaryButton
    }

    let ROOT_VIEW = Selector.anyId(
        IDs.rootView,
        description: "Feature root view",
        groups: ["feature"]
    )

    let TITLE_LABEL = Selector.staticTextId(
        IDs.titleLabel,
        description: "Feature title label",
        groups: ["feature"]
    )

    let PRIMARY_BUTTON = Selector.buttonId(
        IDs.primaryButton,
        description: "Feature primary button",
        groups: ["feature"]
    )

    var all: [Selector] { [
        ROOT_VIEW,
        TITLE_LABEL,
        PRIMARY_BUTTON
    ] }
}
```

## Selector Model

Use a `Selector` abstraction with strategy, value, description, and groups. Add shortcut constructors instead of scattering raw predicates:

```swift
enum SelectorStrategy {
    case buttonById(String)
    case staticTextById(String)
    case anyById(String)
    case predicate(NSPredicate)
}

struct Selector {
    let strategy: SelectorStrategy
    let value: String
    let description: String
    let groups: [String]
}

extension Selector {
    @MainActor
    func element(in app: XCUIApplication) -> XCUIElement {
        switch strategy {
        case .buttonById:
            return app.buttons[value]
        case .staticTextById:
            return app.staticTexts[value]
        case .anyById:
            let button = app.buttons[value]
            if button.exists { return button }
            return app.staticTexts[value]
        case .predicate(let predicate):
            return app.descendants(matching: .any).matching(predicate).element(boundBy: 0)
        }
    }

    static func buttonId(_ id: String, description: String, groups: [String] = []) -> Selector {
        Selector(strategy: .buttonById(id), value: id, description: description, groups: groups)
    }
}
```

## Page Screen

```swift
@MainActor
final class FeatureScreen {
    private let app: XCUIApplication
    private let sel: FeatureSelectorsSet

    init(app: XCUIApplication, selectors: FeatureSelectorsSet = FeatureSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var rootView: XCUIElement { sel.ROOT_VIEW.element(in: app) }
    private var titleLabel: XCUIElement { sel.TITLE_LABEL.element(in: app) }
    private var primaryButton: XCUIElement { sel.PRIMARY_BUTTON.element(in: app) }

    func assertVisible(
        timeout: TimeInterval = UITestWait.normal,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        rootView.assertExists(timeout: timeout, file: file, line: line)
        titleLabel.assertExists(timeout: timeout, file: file, line: line)
    }

    func tapPrimaryButton(
        timeout: TimeInterval = UITestWait.normal,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> DetailsScreen {
        primaryButton.waitAndTap(timeout: timeout, file: file, line: line)

        let details = DetailsScreen(app: app)
        details.assertVisible(timeout: timeout, file: file, line: line)
        return details
    }

    func primaryButtonElement(
        timeout: TimeInterval = UITestWait.normal,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        primaryButton.assertExists(timeout: timeout, file: file, line: line)
        return primaryButton
    }
}
```

Use return-element helpers sparingly for screenshot capture, drag/drop, or cross-screen composition.

For smaller projects, a page object can be a lightweight struct with only `app`, assertions, actions, and returned next pages:

```swift
struct HomePage {
    let app: XCUIApplication

    func assertLoaded(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            app.descendants(matching: .any)[AccessibilityID.Home.screen].waitForExistence(timeout: 5),
            "Home screen did not load.",
            file: file,
            line: line
        )
        XCTAssertTrue(app.buttons[AccessibilityID.Home.addButton].exists)
    }

    func openFirstItem() -> DetailPage {
        let item = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", AccessibilityID.Home.itemRow(""))
        ).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        item.tap()

        let page = DetailPage(app: app)
        page.assertLoaded()
        return page
    }
}
```

This form is still POM: tests do not know selector details, and navigation returns the next page object.

## Test Flow

```swift
@MainActor
final class FeatureTests: UITestCase {
    func testPrimaryActionOpensDetails() {
        let feature = FeatureScreen(app: app)

        feature.assertVisible()
        let details = feature.tapPrimaryButton()

        details.assertVisible()
    }
}
```

Tests should read as scenario steps. Page object methods should hide low-level selector mechanics.

## Screenshot Capture

Keep screenshots separate from page objects. The recommended boundary is:

- `PageScreen`/POM: assert the screen is stable, perform interactions, and expose specific elements only when useful.
- `UITestCase` or another project-local base test class: decide whether screenshots are enabled and provide `captureScreen(...)`.
- `ScreenshotRecorder`: write PNG files, sanitize names, choose output directories, and add `XCTAttachment`.
- Test method: call `captureScreen("StableStateName")` after page assertions or state-changing page methods.

This keeps screenshots from polluting page objects and lets the same POM support normal UI tests, visual documentation, and CI screenshot generation.

Recorder template:

```swift
struct ScreenshotRecorder {
    private let directoryURL: URL
    private let fileManager: FileManager

    init(
        directoryURL: URL = ScreenshotRecorder.defaultDirectoryURL(),
        fileManager: FileManager = .default
    ) {
        self.directoryURL = directoryURL
        self.fileManager = fileManager
    }

    func capture(
        _ screenName: String,
        in testCase: XCTestCase,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let screenshot = XCUIScreen.main.screenshot()
        let safeName = sanitizedFileName(from: screenName)
        let fileURL = directoryURL.appendingPathComponent("\(safeName).png")

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try screenshot.pngRepresentation.write(to: fileURL)
        } catch {
            XCTFail("Failed to save screenshot: \(fileURL.path) - \(error)", file: file, line: line)
        }

        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = screenName
        attachment.lifetime = .keepAlways
        testCase.add(attachment)
    }

    private static func defaultDirectoryURL(filePath: StaticString = #filePath) -> URL {
        if let path = ProcessInfo.processInfo.environment["UITEST_SCREENSHOT_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }

        let folder = inferredDeviceCategory() == "ipad"
            ? "test_output/screenshots-ipad"
            : "test_output/screenshots"

        return URL(fileURLWithPath: "\(filePath)")
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(folder, isDirectory: true)
    }

    private static func inferredDeviceCategory() -> String {
        let environment = ProcessInfo.processInfo.environment
        let name = environment["SIMULATOR_DEVICE_NAME"]
            ?? environment["SIMULATOR_MODEL_IDENTIFIER"]
            ?? ""

        return name.lowercased().contains("ipad") ? "ipad" : "iphone"
    }

    private func sanitizedFileName(from screenName: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
        let scalars = screenName.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "_"
        }
        let name = String(scalars).trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return name.isEmpty ? "Screenshot" : name
    }
}
```

Base test integration:

```swift
class UITestCase: XCTestCase {
    var app: XCUIApplication!
    private lazy var screenshotRecorder = ScreenshotRecorder()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        configureLaunchEnvironment(app)
        app.launch()
    }

    func captureScreen(
        _ screenName: String,
        always: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard always || ProcessInfo.processInfo.environment["UITEST_SCREENSHOT_DIR"]?.isEmpty == false else {
            return
        }
        screenshotRecorder.capture(screenName, in: self, file: file, line: line)
    }

    func configureLaunchEnvironment(_ app: XCUIApplication) {}
}
```

Screenshot test flow:

```swift
final class HomeScreenUITests: UITestCase {
    func testHomeScreenComponents() {
        let home = HomePage(app: app)
        home.assertLoaded()

        captureScreen("HomeScreen")

        let detail = home.openFirstItem()
        detail.assertLoaded()
        captureScreen("DetailScreen")
    }
}
```

Guidelines:

- Capture after `assertLoaded()` or a page method that waits for the resulting state.
- Prefer screen/state names over test method names: `StudySessionAnswerRevealed`, not `testStudySession_1`.
- Use environment-gated capture for normal CI, and `always: true` only for tests whose purpose is screenshot generation.
- Keep recorder output directories configurable with an env var so CI can collect artifacts without changing tests.
- Do not make page objects call `captureScreen`; that creates coupling between interaction APIs and artifact policy.
- If a screenshot needs a specific element, expose `elementForScreenshot()` from the page object and let the test/recorder decide how to capture.

## Waits And Assertions

Prefer an existing project-local wait layer when one exists. Do not copy framework-specific helper names into a portable test style. If the project does not have helpers yet, define small `XCUIElement` extensions and use them from page objects:

```swift
enum UITestWait {
    static let normal: TimeInterval = 5
}

extension XCUIElement {
    @discardableResult
    func assertExists(
        timeout: TimeInterval = UITestWait.normal,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        XCTAssertTrue(
            waitForExistence(timeout: timeout),
            "Expected element to exist: \(self)",
            file: file,
            line: line
        )
        return self
    }

    func waitAndTap(
        timeout: TimeInterval = UITestWait.normal,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertExists(timeout: timeout, file: file, line: line)

        let predicate = NSPredicate(format: "hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)

        XCTAssertEqual(result, .completed, "Expected element to become hittable: \(self)", file: file, line: line)
        guard result == .completed else { return }

        tap()
    }

    func assertDoesNotExist(
        timeout: TimeInterval = UITestWait.normal,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)

        XCTAssertEqual(result, .completed, "Expected element to disappear: \(self)", file: file, line: line)
    }
}
```

Assert values with targeted messages:

```swift
func assertTabsOpened(expectedCount: Int) {
    tabsButton.assertExists()
    XCTAssertEqual(tabsButton.value as? String, "\(expectedCount)")
}
```
