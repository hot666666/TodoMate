//
//  TaskCard.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import SwiftUI

enum TaskCardStyle {
  case normal
  case compact
}

struct TaskCard: View {
  let task: Todo
  var style: TaskCardStyle = .normal

  private var tagColor: Color {
    guard let firstTag = task.tags.first?.lowercased() else {
      return .gray
    }
    switch firstTag {
    case "design system", "research":
      return DesignSystem.Colors.accentPurple
    case "frontend":
      return DesignSystem.Colors.accentCyan
    case "urgent":
      return DesignSystem.Colors.accentRed
    case "devops":
      return .gray
    default:
      return DesignSystem.Colors.accentIndigo
    }
  }

  private var isDone: Bool {
    task.status == .done
  }

  var body: some View {
    switch style {
    case .normal:
      normalBody
    case .compact:
      compactBody
    }
  }

  // MARK: - Normal Style (Board)

  private var normalBody: some View {
    HStack(spacing: 0) {
      // Left color strip
      Rectangle()
        .fill(tagColor)
        .frame(width: 4)

      VStack(alignment: .leading, spacing: 8) {
        // Tags
        if let firstTag = task.tags.first {
          Text(firstTag)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tagColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tagColor.opacity(0.15))
            .clipShape(.rect(cornerRadius: 4))
        }

        // Title
        Text(task.content)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(isDone ? .secondary : .primary)
          .strikethrough(isDone)
          .lineLimit(2)

        // Description
        if !task.detail.isEmpty {
          Text(task.detail)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }

        // Footer
        HStack {
          Image(systemName: "calendar")
            .font(.caption2)
          Text(task.date.formatted(.dateTime.month(.abbreviated).day()))
            .font(.caption)

          Spacer()

          Circle()
            .fill(Color.secondary.opacity(0.3))
            .frame(width: 24, height: 24)
        }
        .foregroundStyle(.secondary)
      }
      .padding(12)
    }
    .background(DesignSystem.Colors.surfaceDark)
    .clipShape(.rect(cornerRadius: 12))
    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
  }

  // MARK: - Compact Style (Calendar)

  // MARK: - Compact Style (Calendar)

  private var compactBody: some View {
    HStack(alignment: .center, spacing: 0) {
      // Left color strip - thinner for compact
      Rectangle()
        .fill(tagColor)
        .frame(width: 3)

      Text(task.content)
        .font(.caption2.weight(.medium))
        .foregroundStyle(isDone ? .secondary : .primary)
        .strikethrough(isDone)
        .lineLimit(1)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)

      Spacer(minLength: 0)
    }
    .frame(height: 24) // Fixed height for 1 line
    .background(tagColor.opacity(0.1)) // Subtle background tint based on tag
    .clipShape(.rect(cornerRadius: 4))
    .overlay(
      RoundedRectangle(cornerRadius: 4)
        .strokeBorder(tagColor.opacity(0.3), lineWidth: 0.5),
    )
  }
}

#Preview {
  VStack {
    TaskCard(
      task: Todo(
        id: "1",
        groupId: nil,
        owner: "user1",
        content: "Normal Task",
        status: .todo,
        detail: "Detail text",
        date: Date(),
        tags: ["Urgent"],
      ), style: .normal,
    )
    .frame(width: 300)

    TaskCard(
      task: Todo(
        id: "2",
        groupId: nil,
        owner: "user1",
        content: "Compact Task",
        status: .todo,
        detail: "Detail text",
        date: Date(),
        tags: ["Design System"],
      ), style: .compact,
    )
    .frame(width: 150)
  }
  .padding()
}
