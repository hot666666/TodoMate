//
//  WindowManager.swift
//  TodoMate
//
//  Created by hs on 1/21/26.
//

import AppKit
import Common
import SwiftUI

/// 앱의 모든 윈도우(메인 윈도우, 오버레이)를 중앙에서 관리하는 매니저
@MainActor
final class WindowManager {
  // MARK: - Singleton

  static let shared = WindowManager()

  // MARK: - Dependencies

  /// 오버레이 윈도우 컨트롤러 (TodoMateApp에서 주입)
  var overlayController: OverlayViewController?

  /// SwiftUI의 openWindow 액션 (TodoMateApp에서 주입)
  var openWindowAction: OpenWindowAction?

  private init() {}

  // MARK: - Overlay Control

  /// 오버레이 윈도우 토글 (⇧⌘Space)
  func toggleOverlay() {
    guard let overlay = overlayController else { return }

    if overlay.isVisible {
      overlay.close()
      // 메인 윈도우가 없으면 앱을 숨겨서 이전 앱으로 포커스 복귀
      if !isMainWindowVisible {
        NSApp.hide(nil)
      }
    } else {
      // 오버레이 표시 전 앱 활성화
      NSApp.activate(ignoringOtherApps: true)
      overlay.show()
    }
  }

  // MARK: - Main Window Control

  /// 메인 윈도우 열기/표시 (⇧⌘N, MenuBar, Dock)
  func openMainWindow() {
    if let existing = findMainWindow() {
      // 이미 존재하면 포커스
      existing.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
    } else {
      // 없으면 새로 생성
      openWindowAction?(id: AppSceneID.mainApp.rawValue)
      NSApp.activate(ignoringOtherApps: true)
    }
  }

  // MARK: - Private Helpers

  /// 메인 윈도우가 현재 보이는지 확인
  var isMainWindowVisible: Bool {
    findMainWindow() != nil
  }

  /// 메인 윈도우 찾기
  private func findMainWindow() -> NSWindow? {
    NSApp.windows.first { window in
      // SwiftUI Window의 identifier는 Window(id:)로 설정한 값과 매칭
      window.identifier?.rawValue == AppSceneID.mainApp.rawValue && window.isVisible
    }
  }
}
