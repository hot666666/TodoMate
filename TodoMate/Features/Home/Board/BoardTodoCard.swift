//
//  BoardTodoCard.swift
//  TodoMate
//
//  Created by agent on 1/20/26.
//

import SimpleOverlaySystem
import SwiftUI
import TodoMateDomain

struct BoardTodoCard: View {
  // MARK: - Environment

  @Environment(TodoBoardStore.self) private var store
  @Environment(\.overlayManager) private var overlay

  // MARK: - Properties

  let todo: Todo

  // MARK: - Body

  var body: some View {
    content
      .statusStrip(color: todo.status.displayColor)
      .materialCard()
      .todoContextMenu(
        todo: todo,
        onStatusChange: { store.updateStatus(todo, status: $0) },
        onDuplicate: { store.duplicate(todo) },
        onDelete: { store.deleteTodo(todo) },
      )
      .onTapGesture { presentTodoSheet() }
  }

  // MARK: - Subviews

  private var content: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(todo.content)
        .todoTextStyle(isDone: todo.status == .complete)
        .font(.subheadline.weight(.semibold))
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)

      if !todo.detail.isEmpty {
        Text(todo.detail)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }

      HStack {
        Image(systemName: "calendar")
          .font(.caption2)
        Text(todo.date.formatted(date: .numeric, time: .omitted))
          .font(.caption)

        Spacer()

        Button {
          store.updateStatus(todo, status: todo.status.next)
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

  // MARK: - Actions

  private func presentTodoSheet() {
    overlay?.presentCentered(
      id: .todoSheet,
      backdropOpacity: 0,
      offset: CGPoint(x: 0, y: -120),
    ) {
      TodoSheet(editableTodo: EditableTodo(from: todo))
    }
  }
}

#Preview {
  BoardTodoCard(todo: .stub)
}
