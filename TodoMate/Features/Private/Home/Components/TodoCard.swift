//
//  TodoCard.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI
import TodoMateDomain

struct TodoCard: View {
  @Environment(\.colorScheme) private var colorScheme

  let todo: Todo
  var onStatusClick: (() -> Void)?
  var onStatusChange: ((TodoStatus) -> Void)?
  var onDuplicate: (() -> Void)?
  var onDelete: (() -> Void)?

  private var accentColor: Color {
    todo.status.displayColor
  }

  private var isDone: Bool {
    todo.status == .complete
  }

  var body: some View {
    normalBody
      .contextMenu { contextMenuContent }
  }

  // MARK: - Normal Style (Board)

  private var normalBody: some View {
    HStack(spacing: 0) {
      // Left color strip
      Rectangle()
        .fill(accentColor)
        .frame(width: 4)

      VStack(alignment: .leading, spacing: 8) {
        // Title
        Text(todo.content)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(isDone ? .secondary : .primary)
          .strikethrough(isDone)
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
}

// MARK: - Context Menu Extension

private extension TodoCard {
  @ViewBuilder
  var contextMenuContent: some View {
    // Status Change
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

    // Actions
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
  VStack {
    TodoCard(
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

    TodoCard(
      todo: Todo(
        content: "Done Task",
        status: .complete,
        detail: "Detail text",
        date: .now,
        createdAt: .now,
        updatedAt: .now,
        owner: "user1",
        isDeleted: false,
      ),
    )
    .frame(width: 300)
  }
  .padding()
}
