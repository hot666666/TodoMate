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
      placement: .bottom(spacing: 4, alignment: .center),
      dismissPolicy: .tap,
      barrier: .blockAll,
      backdropOpacity: 0,
    ) {
      TodoStatusChip(status: status)
    } content: {
      TodoStatusPicker(
        selectedStatus: status,
        onSelect: { newStatus in
          status = newStatus
          overlay?.dismissTop()
        },
      )
      .onKeyPress(.escape) {
        overlay?.dismissTop()
        return .handled
      }
    }
    .buttonStyle(.plain)
  }
}
