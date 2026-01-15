//
//  CalendarWeekday.swift
//  TodoMate
//
//  Created by hs on 1/5/26.
//

import SwiftUI

struct CalendarWeekday: View {
  private let daysOfWeek = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
  private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

  var body: some View {
    LazyVGrid(columns: columns, spacing: 0) {
      ForEach(daysOfWeek, id: \.self) { day in
        Text(day)
          .font(.caption2)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 4)
      }
    }
  }
}

#Preview {
  CalendarWeekday()
    .frame(width: 300)
}
