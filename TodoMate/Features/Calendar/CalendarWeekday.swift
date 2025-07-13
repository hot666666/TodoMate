//
//  CalendarWeekday.swift
//  Todo
//
//  Created by hs on 6/29/25.
//

import SwiftUI

struct CalendarWeekday: View {
  var body: some View {
    LazyVGrid(columns: CalendarDesignSystem.Layout.columns, spacing: CalendarDesignSystem.Layout.gridSpacing) {
      ForEach(CalendarDesignSystem.Weekdays.korean, id: \.self) { day in
        Text(day)
          .font(CalendarDesignSystem.Component.Typography.weekdayFont)
          .fontWeight(.medium)
          .foregroundColor(.secondary.opacity(0.8))
          .frame(maxWidth: .infinity, alignment: .center)
      }
    }
    .padding(.top, CalendarDesignSystem.Component.Weekday.topPadding)
    .padding(.bottom, CalendarDesignSystem.Component.Weekday.bottomPadding)
  }
}

#Preview {
  CalendarWeekday()
    .frame(width: 300, height: 50)
}
