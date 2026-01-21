//
//  GlobalHotKeyModifier.swift
//  TodoMate
//
//  Created by agent on 1/20/26.
//

import SwiftUI

struct GlobalHotKeyModifier: ViewModifier {
  let key: HotKeyManager.Key
  let modifiers: NSEvent.ModifierFlags
  let action: () -> Void

  @Environment(CoreDIContainer.self) private var coreDI
  @State private var token: HotKeyManager.RegistrationToken?

  func body(content: Content) -> some View {
    content
      .onAppear {
        if token == nil {
          token = coreDI.hotKeyManager.register(key: key, modifiers: modifiers) {
            Task { @MainActor in action() }
          }
        }
      }
      .onDisappear {
        if let currentToken = token {
          coreDI.hotKeyManager.unregister(currentToken)
          token = nil
        }
      }
  }
}

extension View {
  /// Registers a global hotkey while this view is active.
  func onGlobalHotKey(
    _ key: HotKeyManager.Key,
    modifiers: NSEvent.ModifierFlags = [],
    perform action: @escaping () -> Void,
  ) -> some View {
    modifier(GlobalHotKeyModifier(key: key, modifiers: modifiers, action: action))
  }
}
