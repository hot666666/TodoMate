//
//  SidebarItemView.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import SwiftUI

struct SidebarItemView: View {
  let title: String
  let icon: String
  let count: Int?
  let isSelected: Bool
  var iconColor: Color?

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 16))
        .foregroundStyle(isSelected ? .white : (iconColor ?? .secondary))
        .frame(width: 20)

      Text(title)
        .font(.body)
        .fontWeight(isSelected ? .medium : .regular)
        .foregroundStyle(isSelected ? .white : .primary)

      Spacer()

      if let count {
        Text("\(count)")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(isSelected ? DesignSystem.Colors.primary : Color.clear),
    )
    .contentShape(Rectangle())
  }
}

#Preview {
  VStack(spacing: 4) {
    SidebarItemView(
      title: "All Tasks", icon: "checkmark.circle.fill", count: 12, isSelected: true,
      iconColor: .blue,
    )
    SidebarItemView(title: "Upcoming", icon: "calendar", count: nil, isSelected: false)
    SidebarItemView(
      title: "Important", icon: "star.fill", count: 3, isSelected: false, iconColor: .yellow,
    )
  }
  .padding()
  .frame(width: 250)
  .background(Color(nsColor: .windowBackgroundColor))
}
