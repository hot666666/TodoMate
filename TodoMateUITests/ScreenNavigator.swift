//
//  ScreenNavigator.swift
//  TodoMateUITests
//
//  Created by hs on 2026/01/06.
//

import XCTest

/// UI 테스트에서 특정 화면으로 네비게이션하는 헬퍼
@MainActor
struct ScreenNavigator {
  let app: XCUIApplication

  /// 지정된 화면으로 네비게이션
  /// - Parameter screen: 목표 화면 타입
  func navigate(to screen: ScreenType) {
    print("📍 Navigating to: \(screen.rawValue)")

    // 1. 사이드바 요소 탭
    if let sidebarId = screen.sidebarIdentifier {
      tapSidebarItem(identifier: sidebarId)
    }

    // 2. ViewMode 전환 (Board/Calendar)
    if screen.requiresViewModeSwitch, let viewMode = screen.viewMode {
      switchViewMode(to: viewMode)
    }

    // 3. 화면이 나타날 때까지 대기
    waitForScreen(screen)
  }

  /// 그룹 피드로 네비게이션 (동적 그룹 ID 사용)
  /// - Parameter groupId: 그룹 ID
  func navigateToGroupFeed(groupId: String) {
    print("📍 Navigating to group feed: \(groupId)")
    let sidebarId = "sidebar_group_\(groupId)"
    tapSidebarItem(identifier: sidebarId)
    waitForElement(identifier: "groupFeedView")
  }

  // MARK: - Private Helpers

  private func tapSidebarItem(identifier: String) {
    let element = app.buttons[identifier].firstMatch
    if element.waitForExistence(timeout: 5) {
      element.tap()
      print("  ✓ Tapped sidebar: \(identifier)")
    } else {
      print("  ✗ Sidebar item not found: \(identifier)")
    }
  }

  private func switchViewMode(to mode: String) {
    // Try radio button first (macOS Toolbar interactions)
    let radioButton = app.radioButtons["viewMode_\(mode)"].firstMatch
    if radioButton.exists {
      radioButton.click() // Use click() for macOS
      print("  ✓ Switched to viewMode (radio): \(mode)")
      return
    }

    // Fallback to Segmented Control
    let picker = app.segmentedControls["viewModePicker"].firstMatch
    if picker.waitForExistence(timeout: 2) {
      let button = picker.buttons["viewMode_\(mode)"].firstMatch
      if button.exists {
        button.tap()
        print("  ✓ Switched to viewMode (segmented): \(mode)")
        return
      }
    }

    print("  ✗ ViewMode switcher not found for: \(mode)")
  }

  private func waitForScreen(_ screen: ScreenType) {
    waitForElement(identifier: screen.accessibilityIdentifier)
  }

  private func waitForElement(identifier: String) {
    let element = app.otherElements[identifier].firstMatch
    if element.waitForExistence(timeout: 5) {
      print("  ✓ Screen appeared: \(identifier)")
    } else {
      // 다른 요소 타입으로도 시도
      let anyElement = app.descendants(matching: .any)[identifier].firstMatch
      if anyElement.waitForExistence(timeout: 2) {
        print("  ✓ Screen appeared (any): \(identifier)")
      } else {
        print("  ✗ Screen not found: \(identifier)")
      }
    }
  }
}
