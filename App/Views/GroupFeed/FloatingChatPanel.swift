//
//  FloatingChatPanel.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import AppKit
import SwiftUI

// MARK: - Floating Panel (NSPanel subclass)

final class FloatingChatPanel: NSPanel {
  private var initialMouseLocation: NSPoint = .zero

  init(contentRect: NSRect, content: some View) {
    super.init(
      contentRect: contentRect,
      styleMask: [.borderless, .nonactivatingPanel, .resizable],
      backing: .buffered,
      defer: false,
    )

    // Panel configuration
    isFloatingPanel = true
    level = .floating
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    isMovableByWindowBackground = true
    hasShadow = true
    backgroundColor = .clear
    isOpaque = false

    // Size constraints
    minSize = NSSize(width: 300, height: 400)
    maxSize = NSSize(width: 600, height: 900)

    // Host SwiftUI content
    let hostingView = NSHostingView(rootView: content)
    hostingView.translatesAutoresizingMaskIntoConstraints = false
    contentView = hostingView
  }

  // Allow key events
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { false }

  // Smooth corner radius
  override var contentView: NSView? {
    didSet {
      contentView?.wantsLayer = true
      contentView?.layer?.cornerRadius = 16
      contentView?.layer?.masksToBounds = true
    }
  }
}

// MARK: - Panel Controller

@MainActor
@Observable
final class FloatingChatPanelController {
  private var panel: FloatingChatPanel?
  var isVisible: Bool = false

  func show(content: some View, relativeTo parentWindow: NSWindow?) {
    guard panel == nil else {
      panel?.orderFront(nil)
      isVisible = true
      return
    }

    // Calculate initial position (bottom right of parent window or screen)
    let screenFrame = parentWindow?.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
    let panelWidth: CGFloat = 340
    let panelHeight: CGFloat = 500
    let padding: CGFloat = 20

    let posX = screenFrame.maxX - panelWidth - padding
    let posY = screenFrame.minY + padding

    let contentRect = NSRect(x: posX, y: posY, width: panelWidth, height: panelHeight)

    panel = FloatingChatPanel(contentRect: contentRect, content: content)
    panel?.orderFront(nil)
    isVisible = true
  }

  func hide() {
    panel?.orderOut(nil)
    isVisible = false
  }

  func close() {
    panel?.close()
    panel = nil
    isVisible = false
  }

  func toggle(content: some View, relativeTo parentWindow: NSWindow?) {
    if isVisible {
      hide()
    } else {
      show(content: content, relativeTo: parentWindow)
    }
  }
}

// MARK: - SwiftUI Environment Key

private struct FloatingChatPanelControllerKey: EnvironmentKey {
  static let defaultValue: FloatingChatPanelController? = nil
}

extension EnvironmentValues {
  var floatingChatPanelController: FloatingChatPanelController? {
    get { self[FloatingChatPanelControllerKey.self] }
    set { self[FloatingChatPanelControllerKey.self] = newValue }
  }
}
