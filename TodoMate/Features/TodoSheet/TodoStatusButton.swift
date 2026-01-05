//
//  TodoStatusButton.swift
//  Todo
//
//  Created by hs on 6/29/25.
//

import SwiftUI

struct TodoStatusButton: View {
  @Environment(OverlayManager.self) private var overlayManager
  @Binding var status: TodoStatus
  @State private var buttonFrame: CGRect = .zero

  var body: some View {
    TodoStatusChip(
      status: status,
      action: {
        let anchorPoint = CGPoint(
          x: buttonFrame.midX,
          y: buttonFrame.minY,
        )

        overlayManager.presentPopover(
          anchorPoint: anchorPoint,
          popoverType: .status,
          buttonWidth: buttonFrame.width,
          buttonHeight: buttonFrame.height,
        ) {
          TodoStatusPicker(
            selectedStatus: status,
            onStatusSelected: { newStatus in
              status = newStatus
              overlayManager.pop()
            },
          )
          .onKeyPress(.escape) {
            overlayManager.pop()
            return .handled
          }
        }
      },
    )
    .background(
      GeometryReader { geo in
        Color.clear
          .onAppear {
            buttonFrame = geo.frame(in: .global)
          }
          .onChange(of: geo.frame(in: .global)) { _, newFrame in
            buttonFrame = newFrame
          }
      },
    )
  }
}
