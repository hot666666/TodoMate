//
//  StatusBadge.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import SwiftUI

struct StatusBadge: View {
  let title: String
  let color: Color
  let icon: String?

  var body: some View {
    HStack(spacing: 4) {
      if let icon {
        Image(systemName: icon)
          .font(.caption2)
      }
      Text(title)
        .font(.caption2)
        .fontWeight(.semibold)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(color.opacity(0.15))
    .foregroundStyle(color)
    .clipShape(Capsule())
  }
}

#Preview {
  HStack {
    StatusBadge(title: "Design System", color: DesignSystem.Colors.accentPurple, icon: nil)
    StatusBadge(title: "Urgent", color: .red, icon: "exclamationmark.triangle.fill")
    StatusBadge(
      title: "Frontend", color: DesignSystem.Colors.accentCyan, icon: "laptopcomputer",
    )
  }
  .padding()
}
