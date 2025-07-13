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
    editableTodo: EditableTodo? = nil,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping () -> some View
  ) {
    let item = OverlayItem(
      type: .sheet,
      content: AnyView(content()),
      onDismiss: onDismiss,
      canDismiss: nil,
      editableTodo: editableTodo
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

  func popWithConfirmation() {
    guard let item = overlays.last else { return }

    // TodoSheet이고 EditableTodo가 있는 경우 상황에 따라 처리
    if item.type == .sheet, let editableTodo = item.editableTodo {
      if editableTodo.isDirty {
        let title = editableTodo.isNew ? "작성 중인 내용을 폐기하시겠습니까?" : "변경사항을 폐기하시겠습니까?"
        let message = editableTodo.isNew ? "작성 중인 내용이 사라집니다." : "저장하지 않은 변경사항이 있습니다."

        presentConfirmation(
          title: title,
          message: message,
          destructiveActionTitle: "폐기",
          cancelTitle: "취소"
        ) {
          // confirmation은 ConfirmationView의 onDismiss에서 자동으로 pop됨
          // 여기서는 TodoSheet만 처리
          if self.overlays.count >= 2 {
            let sheetItem = self.overlays[self.overlays.count - 2] // confirmation 아래의 sheet
            if sheetItem.type == .sheet {
              self.overlays.remove(at: self.overlays.count - 2) // TodoSheet 닫기
              sheetItem.onDismiss?()
            }
          }
        }
        return
      }
    }

    // 일반적인 경우 바로 pop
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
    let editableTodo: EditableTodo?

    init(
      type: OverlayType,
      content: AnyView,
      onDismiss: (() -> Void)? = nil,
      canDismiss: (() -> Bool)? = nil,
      anchorPoint: CGPoint? = nil,
      popoverType: PopoverType? = nil,
      buttonWidth: CGFloat? = nil,
      buttonHeight: CGFloat? = nil,
      editableTodo: EditableTodo? = nil
    ) {
      self.type = type
      self.content = content
      self.onDismiss = onDismiss
      self.canDismiss = canDismiss
      self.anchorPoint = anchorPoint
      self.popoverType = popoverType
      self.buttonWidth = buttonWidth
      self.buttonHeight = buttonHeight
      self.editableTodo = editableTodo
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
