//
//  WindowHelper.swift
//  Todo
//
//  Created by hs on 6/7/25.
//

import SwiftUI

enum WindowHelper {
  static var isToolbarVisible: Bool {
    guard let window = NSApp.keyWindow else { return false }
    return window.toolbar?.isVisible ?? false
  }

  static func hideToolbarForWindow() {
    guard let window = NSApp.keyWindow else { return }

    window.toolbar?.isVisible = false
  }

  static func showToolbarForWindow() {
    guard let window = NSApp.keyWindow else { return }

    window.toolbar?.isVisible = true
  }
}
