//
//  TodoRow.swift
//  TodoMate
//
//  Created by hs on 3/9/25.
//

import SwiftUI

struct TodoRow: View {
  @Environment(\.widgetFamily) var widgetFamily
  let todo: WidgetTodo

  var body: some View {
    HStack(alignment: .center, spacing: 10) {
      statusChip

      Text(todo.contentOrPlaceholder)
        .font(widgetFamily == .systemSmall ? .caption : .body)
        .lineLimit(1)

      Spacer()
    }
    .padding(5)
  }

  @ViewBuilder
  private var statusChip: some View {
    // TODO: - NavigationLink
    Button(action: {}) {
      HStack {
        Spacer()
        Text("진행 중")
          .foregroundColor(.white)
          .font(widgetFamily == .systemSmall ? .caption : .body)
          .lineLimit(1)
          .fixedSize()
        Spacer()
      }
      .padding(3)
    }
    .frame(width: widgetFamily == .systemSmall ? 50 : 70)
    .background(Color.customBlue)
    .clipShape(Capsule())
  }
}
