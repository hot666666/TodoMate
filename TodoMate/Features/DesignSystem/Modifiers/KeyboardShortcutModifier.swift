//
//  KeyboardShortcutModifier.swift
//  TodoMate
//
//  ViewModifier for adding hidden button keyboard shortcuts to any view.
//
//  Created by agent on 1/21/26.
//

import SwiftUI

/// 숨겨진 버튼으로 키보드 단축키를 뷰에 추가하는 ViewModifier
struct KeyboardShortcutModifier: ViewModifier {
  let key: KeyEquivalent
  let modifiers: EventModifiers
  let action: () -> Void

  func body(content: Content) -> some View {
    content
      .overlay {
        Button(action: action) {
          EmptyView()
        }
        .keyboardShortcut(key, modifiers: modifiers)
        .opacity(0)
        .allowsHitTesting(false)
      }
  }
}

extension View {
  /// 뷰에 숨겨진 버튼으로 키보드 단축키를 추가합니다.
  ///
  /// - Parameters:
  ///   - key: 키보드 키 (예: "b", "t")
  ///   - modifiers: 수정자 키 (예: .command, [.command, .shift])
  ///   - action: 단축키가 눌렸을 때 실행할 액션
  /// - Returns: 키보드 단축키가 적용된 뷰
  ///
  /// ```swift
  /// // 사용 예시
  /// myView
  ///   .hiddenKeyboardShortcut("b", modifiers: .command) {
  ///     toggleSidebar()
  ///   }
  /// ```
  func hiddenKeyboardShortcut(
    _ key: KeyEquivalent,
    modifiers: EventModifiers = .command,
    action: @escaping () -> Void,
  ) -> some View {
    modifier(KeyboardShortcutModifier(key: key, modifiers: modifiers, action: action))
  }
}
