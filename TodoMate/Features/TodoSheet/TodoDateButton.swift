//
//  TodoDateButton.swift
//  Todo
//
//  Created by hs on 6/29/25.
//

import SwiftUI

struct TodoDateButton: View {
  @Environment(OverlayManager.self) private var overlayManager
  @Binding var date: Date
  @State private var buttonFrame: CGRect = .zero

  var body: some View {
    Button(action: {
      let anchorPoint = CGPoint(
        x: buttonFrame.minX,
        y: buttonFrame.minY
      )

      overlayManager.presentPopover(
        anchorPoint: anchorPoint,
        popoverType: .date,
        buttonWidth: buttonFrame.width,
        buttonHeight: buttonFrame.height
      ) {
        TodoDatePicker(date: $date)
      }
    }) {
      Text(date.yearMonthDay)
        .font(TodoSheetDesignSystem.Component.Typography.captionFont)
        .fontWeight(.medium)
        .foregroundColor(.primary)
        .padding(.horizontal, TodoSheetDesignSystem.Padding.small)
        .padding(.vertical, TodoSheetDesignSystem.Padding.xSmall)
        .background(Color.black.opacity(0.5))
        .cornerRadius(TodoSheetDesignSystem.CornerRadius.small)
    }
    .buttonStyle(.plain)
    .background(
      GeometryReader { geo in
        Color.clear
          .onAppear {
            buttonFrame = geo.frame(in: .global)
          }
          .onChange(of: geo.frame(in: .global)) { _, newFrame in
            buttonFrame = newFrame
          }
      }
    )
  }
}
