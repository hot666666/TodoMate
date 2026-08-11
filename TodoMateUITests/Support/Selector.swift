import XCTest

enum SelectorStrategy {
  case anyByID
  case buttonByID
  case textFieldByID
  case staticTextByID
}

struct Selector {
  let strategy: SelectorStrategy
  let identifier: String
  let description: String

  @MainActor
  func element(in app: XCUIApplication) -> XCUIElement {
    switch strategy {
    case .anyByID:
      app.descendants(matching: .any)[identifier].firstMatch
    case .buttonByID:
      app.buttons[identifier].firstMatch
    case .textFieldByID:
      app.textFields[identifier].firstMatch
    case .staticTextByID:
      app.staticTexts[identifier].firstMatch
    }
  }
}
