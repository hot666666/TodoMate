//
//  View+Extension.swift
//  Todo
//
//  Created by hs on 6/7/25.
//

import SwiftUI

// MARK: - Key Press 감지 처리

struct KeyPressModifier: ViewModifier {
  let keyCode: UInt16
  let action: () -> Void

  @State private var monitor: Any?

  func body(content: Content) -> some View {
    content
      .onAppear {
        // Add the monitor and assign it
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
          if event.keyCode == keyCode {
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

extension View {
  func onKeyPress(keyCode: UInt16, perform action: @escaping () -> Void) -> some View {
    modifier(KeyPressModifier(keyCode: keyCode, action: action))
  }
}
