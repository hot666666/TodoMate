//
//  TodoStatusButton.swift
//  Todo
//
//  Created by hs on 6/29/25.
//

import SimpleOverlaySystem
import SwiftUI

struct TodoStatusButton: View {
  @Environment(\.overlayManager) private var overlay
  @Binding var status: TodoStatus

  var body: some View {
    AnchoredOverlayButton(
      placement: .bottom(alignment: .center),
      dismissPolicy: .tap,
      barrier: .blockAll,
    ) {
      // Use forceInteractive since the button wrapper provides the interaction
      TodoStatusChip(status: status, action: nil, forceInteractive: true)
    } content: {
      TodoStatusPicker(
        selectedStatus: status,
        onStatusSelected: { newStatus in
          status = newStatus
          overlay?.dismissTop()
        },
      )
      .onKeyPress(.escape) {
        overlay?.dismissTop()
        return .handled
      }
    }
  }
}
