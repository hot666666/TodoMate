//
//  TodoCard.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI
import TodoMateDomain

enum TodoCardStyle {
  case normal
  case compact
}

struct TodoCard: View {
  // MARK: - Properties

  @Environment(\.colorScheme) private var colorScheme

  var style: TodoCardStyle = .normal
  let todo: Todo
  var onStatusClick: (() -> Void)?
  var onStatusChange: ((TodoStatus) -> Void)?
  var onDuplicate: (() -> Void)?
  var onDelete: (() -> Void)?

  // MARK: - Computed Properties

  private var accentColor: Color {
    todo.status.displayColor
  }

  private var isDone: Bool {
    todo.status == .complete
  }

  // MARK: - Body

  var body: some View {
    Group {
      switch style {
      case .normal:
        normalBody
      case .compact:
        compactBody
      }
    }
    .contextMenu { contextMenuContent }
  }

  // MARK: - Subviews

  private var statusStrip: some View {
    Rectangle()
      .fill(accentColor)
      .frame(width: style == .normal ? 4 : 3)
  }

  private func todoTitle(_ text: String) -> Text {
    Text(text)
      .foregroundStyle(isDone ? .secondary : .primary)
      .strikethrough(isDone)
  }

  private func cardLayout(@ViewBuilder content: () -> some View) -> some View {
    HStack(spacing: 0) {
      statusStrip
      content()
    }
  }

  // MARK: - Normal Style (Board)

  private var normalBody: some View {
    cardLayout {
      VStack(alignment: .leading, spacing: 8) {
        // Title
        todoTitle(todo.content)
          .font(.subheadline.weight(.semibold))
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)

        // Description
        if !todo.detail.isEmpty {
          Text(todo.detail)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }

        // Footer
        HStack {
          Image(systemName: "calendar")
            .font(.caption2)
          Text(todo.date.formatted(date: .numeric, time: .omitted))
            .font(.caption)

          Spacer()

          Button {
            onStatusClick?()
          } label: {
            Image(systemName: todo.status.filledIconName)
              .foregroundStyle(todo.status.displayColor)
          }
          .buttonStyle(.plain)
          .frame(width: 24, height: 24)
        }
        .foregroundStyle(.secondary)
      }
      .padding(12)
    }
    .background(.regularMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
  }

  // MARK: - Compact Style (Calendar)

  private var compactBody: some View {
    cardLayout {
      todoTitle(todo.content)
        .font(.caption2.weight(.medium))
        .lineLimit(1)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)

      Spacer(minLength: 0)
    }
    .frame(height: 24)
    .background(accentColor.opacity(0.1))
    .clipShape(.rect(cornerRadius: 4))
    .overlay(
      RoundedRectangle(cornerRadius: 4)
        .strokeBorder(accentColor.opacity(0.3), lineWidth: 0.5),
    )
  }
}

// MARK: - Context Menu Extension

private extension TodoCard {
  @ViewBuilder
  var contextMenuContent: some View {
    Menu {
      ForEach(TodoStatus.allCases, id: \.self) { status in
        if status != todo.status {
          Button {
            onStatusChange?(status)
          } label: {
            Label(status.displayName, systemImage: status.iconName)
          }
        }
      }
    } label: {
      Label("Change Status", systemImage: "arrow.triangle.2.circlepath")
    }

    Divider()

    if let onDuplicate {
      Button {
        onDuplicate()
      } label: {
        Label("Duplicate", systemImage: "plus.square.on.square")
      }
    }

    if let onDelete {
      Button(role: .destructive) {
        onDelete()
      } label: {
        Label("Delete", systemImage: "trash")
      }
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    // Normal Style
    TodoCard(
      style: .normal,
      todo: Todo(
        content: "Normal Task",
        status: .todo,
        detail: "Detail text",
        date: .now,
        createdAt: .now,
        updatedAt: .now,
        owner: "user1",
        isDeleted: false,
      ),
    )
    .frame(width: 300)

    // Compact Style
    TodoCard(
      style: .compact,
      todo: Todo(
        content: "Compact Task",
        status: .complete,
        detail: "Detail text",
        date: .now,
        createdAt: .now,
        updatedAt: .now,
        owner: "user1",
        isDeleted: false,
      ),
    )
    .frame(width: 200)
  }
  .padding()
}
