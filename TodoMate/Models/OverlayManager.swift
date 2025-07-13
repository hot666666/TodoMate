//
//  OverlayManager.swift
//  Todo
//
//  Created by hs on 7/11/25.
//

import SwiftUI

@Observable
final class OverlayManager {
  private(set) var overlays: [OverlayItem] = []

  var isPresented: Bool {
    !overlays.isEmpty
  }

  func presentSheet(
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping () -> some View
  ) {
    let item = OverlayItem(
      type: .sheet,
      content: AnyView(content()),
      onDismiss: onDismiss,
      canDismiss: nil
    )
    overlays.append(item)
  }

  func presentFullScreen(
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping () -> some View
  ) {
    let item = OverlayItem(
      type: .fullScreen,
      content: AnyView(content()),
      onDismiss: onDismiss,
      canDismiss: nil
    )
    overlays.append(item)
  }

  func presentConfirmation(
    title: String,
    message: String? = nil,
    destructiveActionTitle: String,
    cancelTitle: String = "취소",
    destructiveAction: @escaping () -> Void
  ) {
    let confirmationView = ConfirmationView(
      title: title,
      message: message,
      destructiveActionTitle: destructiveActionTitle,
      cancelTitle: cancelTitle,
      destructiveAction: destructiveAction,
      onDismiss: { [weak self] in
        self?.pop()
      }
    )

    let item = OverlayItem(
      type: .confirmation,
      content: AnyView(confirmationView),
      onDismiss: nil,
      canDismiss: nil
    )
    overlays.append(item)
  }

  func presentPopover(
    anchorPoint: CGPoint,
    popoverType: PopoverType = .default,
    buttonWidth: CGFloat? = nil,
    buttonHeight: CGFloat? = nil,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping () -> some View
  ) {
    let item = OverlayItem(
      type: .popover,
      content: AnyView(content()),
      onDismiss: onDismiss,
      canDismiss: nil,
      anchorPoint: anchorPoint,
      popoverType: popoverType,
      buttonWidth: buttonWidth,
      buttonHeight: buttonHeight
    )
    overlays.append(item)
  }

  func pop() {
    guard let item = overlays.last else { return }
    overlays.removeLast()
    item.onDismiss?()
  }

  func clear() {
    overlays.removeAll()
  }

  func canDismissTopOverlay() -> Bool {
    guard let topOverlay = overlays.last else { return false }
    return topOverlay.canDismiss?() ?? true
  }

  func popIfCanDismiss() {
    guard canDismissTopOverlay() else { return }
    pop()
  }
}

extension OverlayManager {
  struct OverlayItem: Identifiable {
    let id = UUID()
    let type: OverlayType
    let content: AnyView
    let onDismiss: (() -> Void)?
    let canDismiss: (() -> Bool)?
    let anchorPoint: CGPoint?
    let popoverType: PopoverType?
    let buttonWidth: CGFloat?
    let buttonHeight: CGFloat?

    init(
      type: OverlayType,
      content: AnyView,
      onDismiss: (() -> Void)? = nil,
      canDismiss: (() -> Bool)? = nil,
      anchorPoint: CGPoint? = nil,
      popoverType: PopoverType? = nil,
      buttonWidth: CGFloat? = nil,
      buttonHeight: CGFloat? = nil
    ) {
      self.type = type
      self.content = content
      self.onDismiss = onDismiss
      self.canDismiss = canDismiss
      self.anchorPoint = anchorPoint
      self.popoverType = popoverType
      self.buttonWidth = buttonWidth
      self.buttonHeight = buttonHeight
    }

    enum OverlayType {
      case sheet
      case fullScreen
      case confirmation
      case popover
    }
  }

  enum PopoverType {
    case `default`
    case status
    case date
  }
}
