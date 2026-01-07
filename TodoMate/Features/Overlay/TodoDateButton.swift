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
        .font(DesignSystem.TodoSheet.Typography.captionFont)
        .fontWeight(.medium)
        .foregroundColor(.primary)
        .padding(.horizontal, DesignSystem.TodoSheet.Padding.small)
        .padding(.vertical, DesignSystem.TodoSheet.Padding.xSmall)
        .background(Color.black.opacity(0.5))
        .cornerRadius(DesignSystem.TodoSheet.CornerRadius.small)
    } content: {
      TodoDatePicker(date: $date)
    }
  }
}
