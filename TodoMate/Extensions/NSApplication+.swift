//
//  NSApplication+.swift
//  TodoMate
//
//  Created by agent on 1/16/26.
//

import AppKit

extension NSApplication {
  /// Dock 아이콘 표시 여부 및 앱 활성화 상태를 업데이트합니다.
  /// - Parameters:
  ///   - showInDock: Dock에 아이콘을 표시할지 여부
  ///   - activate: 설정을 변경하면서 앱을 활성화(포커스)할지 여부 (기본값: false)
  func updateActivationPolicy(showInDock: Bool, activate: Bool = false) {
    setActivationPolicy(showInDock ? .regular : .accessory)
    if showInDock, activate {
      self.activate(ignoringOtherApps: true)
    }
  }
}
