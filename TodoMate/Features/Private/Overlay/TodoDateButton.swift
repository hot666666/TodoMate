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

  private let calendar = Calendar.current

  private var isToday: Bool {
    calendar.isDateInToday(date)
  }

  private var displayText: String {
    isToday ? "오늘" : date.yearMonthDay
  }

  var body: some View {
    AnchoredOverlayButton(
      placement: .bottom(spacing: 4, alignment: .leading),
      dismissPolicy: .tap,
      barrier: .blockAll,
      backdropOpacity: 0,
    ) {
      TagButtonLabel(
        icon: isToday ? "calendar" : "calendar.badge.clock",
        text: displayText,
        isActive: isToday,
        activeColor: .green,
      )
    } content: {
      TodoDatePicker(date: $date)
    }
    .buttonStyle(.plain)
  }
}
