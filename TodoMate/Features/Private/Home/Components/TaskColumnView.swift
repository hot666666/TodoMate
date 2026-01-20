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
      HStack {
        HStack(spacing: 8) {
          Circle()
            .fill(color)
            .frame(width: 8, height: 8)
          Text(title)
            .font(.system(size: 14, weight: .bold))
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
      .background(Color.white.opacity(0.02))

      content
    }
    .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
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

          TodoCard(todo: .stub)
            .padding(5)
        }
      }
      .frame(width: 300, height: 400)
    }
  }
  .frame(width: 400, height: 500)
}
