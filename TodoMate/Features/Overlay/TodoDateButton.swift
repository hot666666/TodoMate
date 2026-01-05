//
//  TodoDateButton.swift
//  Todo
//
//  Created by hs on 6/29/25.
//

import SimpleOverlaySystem
import SwiftUI

struct TodoDateButton: View {
  @Environment(\.overlayManager) private var overlay
  @Binding var date: Date

  var body: some View {
    AnchoredOverlayButton(
      placement: .bottom(alignment: .center),
      dismissPolicy: .tap,
      barrier: .blockAll,
    ) {
      Text(date.yearMonthDay)
        .font(TodoSheetDesignSystem.Component.Typography.captionFont)
        .fontWeight(.medium)
        .foregroundColor(.primary)
        .padding(.horizontal, TodoSheetDesignSystem.Padding.small)
        .padding(.vertical, TodoSheetDesignSystem.Padding.xSmall)
        .background(Color.black.opacity(0.5))
        .cornerRadius(TodoSheetDesignSystem.CornerRadius.small)
    } content: {
      TodoDatePicker(date: $date)
    }
  }
}
