//
//  View+Extension.swift
//  Todo
//
//  Created by hs on 6/7/25.
//

import SwiftUI

// MARK: - Key Press 감지 처리

enum KeyboardShortcuts {
  case escape
  case newTodo

  var keyCode: UInt16 {
    switch self {
    case .escape: 53
    case .newTodo: 45 // N key
    }
  }

  var modifiers: NSEvent.ModifierFlags {
    switch self {
    case .escape: []
    case .newTodo: .command
    }
  }
}

struct KeyPressModifier: ViewModifier {
  let keyCode: UInt16
  let modifiers: NSEvent.ModifierFlags
  let action: () -> Void

  @State private var monitor: Any?

  func body(content: Content) -> some View {
    content
      .onAppear {
        // Add the monitor and assign it
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
          if event.keyCode == keyCode, event.modifierFlags.intersection(.deviceIndependentFlagsMask) == modifiers {
            action()
            return nil
          }
          return event
        }
      }
      .onDisappear {
        // Remove the monitor if it exists
        if let monitor {
          NSEvent.removeMonitor(monitor)
          self.monitor = nil
        }
      }
  }
}

struct KeyboardShortcutHandler {
  let shortcut: KeyboardShortcuts
  let action: () -> Void
}

struct MultiKeyPressModifier: ViewModifier {
  let handlers: [KeyboardShortcutHandler]
  @State private var monitor: Any?

  func body(content: Content) -> some View {
    content
      .onAppear {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
          for handler in handlers {
            if event.keyCode == handler.shortcut.keyCode,
               event.modifierFlags.intersection(.deviceIndependentFlagsMask) == handler.shortcut.modifiers
            {
              handler.action()
              return nil
            }
          }
          return event
        }
      }
      .onDisappear {
        if let monitor {
          NSEvent.removeMonitor(monitor)
          self.monitor = nil
        }
      }
  }
}

extension View {
  func onKeyPress(keyCode: UInt16, modifiers: NSEvent.ModifierFlags = [], perform action: @escaping () -> Void) -> some View {
    modifier(KeyPressModifier(keyCode: keyCode, modifiers: modifiers, action: action))
  }

  func onKeyPress(_ shortcuts: [(KeyboardShortcuts, () -> Void)]) -> some View {
    let handlers = shortcuts.map { KeyboardShortcutHandler(shortcut: $0.0, action: $0.1) }
    return modifier(MultiKeyPressModifier(handlers: handlers))
  }
}

// MARK: - List 깔끔 스타일 설정

extension View {
  func simpleListModifier() -> some View {
    listStyle(.inset)
      .scrollContentBackground(.hidden)
      .background(.clear)
  }
}

// MARK: - ScrollToBottom Modifier

struct ScrollToBottomModifier: ViewModifier {
  let anchor: String
  let itemCount: Int

  func body(content: Content) -> some View {
    ScrollViewReader { proxy in
      content
        .onAppear {
          DispatchQueue.main.async {
            proxy.scrollTo(anchor, anchor: .bottom)
          }
        }
        .onChange(of: itemCount) { _, _ in
          withAnimation {
            proxy.scrollTo(anchor, anchor: .bottom)
          }
        }
    }
  }
}

extension View {
  /// 아이템 수가 변경될 때마다 자동으로 하단으로 스크롤합니다.
  /// - Parameters:
  ///   - anchor: 스크롤할 앵커 ID (기본값: "bottom")
  ///   - itemCount: 관찰할 아이템 수
  func scrollToBottomOnChange(anchor: String = "bottom", itemCount: Int) -> some View {
    modifier(ScrollToBottomModifier(anchor: anchor, itemCount: itemCount))
  }
}

// MARK: - Hoverable Modifier

struct HoverableModifier: ViewModifier {
  let backgroundColor: Color
  let cornerRadius: CGFloat
  let animationDuration: Double

  @State private var isHovering = false

  func body(content: Content) -> some View {
    content
      .onHover { hovering in
        withAnimation(.easeInOut(duration: animationDuration)) {
          isHovering = hovering
        }
      }
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(isHovering ? backgroundColor : .clear)
      )
  }
}

extension View {
  /// 호버 시 배경색이 변경되는 애니메이션을 추가합니다.
  /// - Parameters:
  ///   - backgroundColor: 호버 시 표시할 배경색 (기본: .secondary.opacity(0.1))
  ///   - cornerRadius: 모서리 반경 (기본: 8)
  ///   - animationDuration: 애니메이션 지속 시간 (기본: 0.2)
  func hoverable(
    backgroundColor: Color = .secondary.opacity(0.1),
    cornerRadius: CGFloat = 8,
    animationDuration: Double = 0.2
  ) -> some View {
    modifier(HoverableModifier(
      backgroundColor: backgroundColor,
      cornerRadius: cornerRadius,
      animationDuration: animationDuration
    ))
  }
}

// MARK: - Card Background Modifier

struct CardBackgroundModifier: ViewModifier {
  let backgroundColor: Color
  let cornerRadius: CGFloat
  let padding: EdgeInsets

  func body(content: Content) -> some View {
    content
      .padding(padding)
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(backgroundColor)
      )
  }
}

extension View {
  /// 카드 스타일 배경을 추가합니다.
  /// - Parameters:
  ///   - backgroundColor: 배경색 (기본: .clear)
  ///   - cornerRadius: 모서리 반경 (기본: 8)
  ///   - padding: 내부 여백 (기본: 모든 방향 16)
  func cardBackground(
    backgroundColor: Color = .clear,
    cornerRadius: CGFloat = 8,
    padding: EdgeInsets = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
  ) -> some View {
    modifier(CardBackgroundModifier(
      backgroundColor: backgroundColor,
      cornerRadius: cornerRadius,
      padding: padding
    ))
  }
}

// MARK: - Clean List Style

extension View {
  /// 깔끔한 리스트 스타일을 적용합니다 (배경 투명, 구분선 없음).
  func cleanListStyle() -> some View {
    self
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .background(.clear)
  }
}
