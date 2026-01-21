//
//  TaskColumnView.swift
//  TodoMate
//
//  Created by agent on 1/19/26.
//

import SwiftUI
import TodoMateDomain

struct TaskColumnView<Content: View>: View {
  let title: String
  let count: Int
  let color: Color
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header
      HStack {
        HStack(spacing: 8) {
          Circle()
            .fill(color)
            .frame(width: 8, height: 8)
          Text(title)
            .font(.system(size: 14, weight: .bold)) // Bold as per screenshot
            .foregroundStyle(.primary)
        }

        Spacer()

        Text("\(count)")
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .background(Color.secondary.opacity(0.1))
          .clipShape(Capsule())
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(Color.white.opacity(0.02)) // Very subtle header background for differentiation within the column

      // Content List
      content
    }
    // Container Style - The "Card" look for the column itself
    .background(Color(nsColor: .windowBackgroundColor).opacity(0.5)) // Slightly distinct from main background
    // Or closer to screenshot: Dark gray container?
    // Screenshot shows a container that is distinctly visible against the black background.
    // Let's use Color.secondary.opacity(0.05) or Material.
    .background(.regularMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .strokeBorder(Color.white.opacity(0.05), lineWidth: 1),
    )
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()
    HStack {
      TaskColumnView(title: "Incomplete", count: 0, color: .red) {
        ScrollView {
          Text("Task Item")
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            .padding(12)
        }
      }
      .frame(width: 300, height: 500)
    }
  }
}
