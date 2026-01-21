//
//  WindowManagerInjector.swift
//  TodoMate
//
//  Created by hs on 1/21/26.
//

import SwiftUI

/// SwiftUI의 openWindow 액션을 WindowManager에 주입하는 모디파이어
struct WindowManagerInjector: ViewModifier {
  @Environment(\.openWindow) private var openWindow

  func body(content: Content) -> some View {
    content
      .onAppear {
        WindowManager.shared.openWindowAction = openWindow
      }
  }
}
