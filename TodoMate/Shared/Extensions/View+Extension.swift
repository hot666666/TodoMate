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
