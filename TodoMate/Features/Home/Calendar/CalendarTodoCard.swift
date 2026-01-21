//
//  CalendarTodoCard.swift
//  TodoMate
//
//  Created by agent on 1/20/26.
//

import SimpleOverlaySystem
import SwiftUI
import TodoMateDomain

struct CalendarTodoCard: View {
  // MARK: - Environment

  @Environment(TodoCalendarViewModel.self) private var viewModel
  @Environment(\.overlayManager) private var overlay

  // MARK: - Properties

  let todo: Todo

  // MARK: - Body

  var body: some View {
    content
      .statusStrip(color: todo.status.displayColor, width: 3)
      .frame(height: 24)
      .tintedCard(color: todo.status.displayColor, cornerRadius: 4)
      .todoContextMenu(
        todo: todo,
        onStatusChange: { viewModel.updateStatus(todo, to: $0) },
        onDuplicate: { viewModel.duplicate(todo) },
        onDelete: { viewModel.delete(todo) },
      )
      .onTapGesture {
        viewModel.presentTodoSheet(for: todo)
      }
  }

  // MARK: - Subviews

  private var content: some View {
    HStack(spacing: 0) {
      Text(todo.content)
        .todoTextStyle(isDone: todo.status == .complete)
        .font(.caption2.weight(.medium))
        .lineLimit(1)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)

      Spacer(minLength: 0)
    }
  }
}
