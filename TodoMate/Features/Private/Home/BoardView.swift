//
//  BoardView.swift
//  TodoMate
//
//  Kanban-style board view for tasks
//  Created by agent on 1/5/26.
//
//

import SimpleOverlaySystem
import SwiftData
import SwiftUI
import TodoMateDomain

// MARK: - BoardView (Container)

struct BoardView: View {
  // MARK: - Properties

  @Bindable var viewModel: BoardViewModel
  @Environment(TodoBoardStore.self) private var store
  @Environment(\.overlayManager) private var overlay

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      header
        .padding(.horizontal)
        .padding(.top, 8)

      GeometryReader { proxy in
        let spacing: CGFloat = 16
        let horizontalMargin: CGFloat = 16
        let totalSpacing = spacing * 2
        // Safe width calculation to prevent crash
        let visibleWidth = max(0, proxy.size.width - (horizontalMargin * 2))
        let columnWidth = max(0, floor((visibleWidth - totalSpacing) / 3))

        HStack(alignment: .top, spacing: spacing) {
          if viewModel.scrollPosition == .leading {
            TodoColumn(
              status: .todo,
              count: todos(for: .todo).count,
              tasks: todos(for: .todo),
              isToday: { Calendar.current.isDateInToday($0) },
              onTapTask: { presentTodoSheet(for: $0) },
              onStatusChange: { todo in viewModel.advanceStatus(of: todo) },
              onUpdateStatus: { todo, status in viewModel.update(todo, to: status) },
              onDuplicate: { viewModel.duplicate($0) },
              onDelete: { viewModel.delete($0) },
            )
            .dropDestination(for: Todo.self) { items, _ in
              handleDrop(items, to: .todo)
            }
            .frame(width: columnWidth)
            .transition(.move(edge: .leading).combined(with: .opacity))
          }

          TodoColumn(
            status: .inProgress,
            count: todos(for: .inProgress).count,
            tasks: todos(for: .inProgress),
            isToday: { Calendar.current.isDateInToday($0) },
            onTapTask: { presentTodoSheet(for: $0) },
            onStatusChange: { todo in viewModel.advanceStatus(of: todo) },
            onUpdateStatus: { todo, status in viewModel.update(todo, to: status) },
            onDuplicate: { viewModel.duplicate($0) },
            onDelete: { viewModel.delete($0) },
          )
          .dropDestination(for: Todo.self) { items, _ in
            handleDrop(items, to: .inProgress)
          }
          .frame(width: columnWidth)

          TodoColumn(
            status: .complete,
            count: todos(for: .complete).count,
            tasks: todos(for: .complete),
            isToday: { Calendar.current.isDateInToday($0) },
            onTapTask: { presentTodoSheet(for: $0) },
            onStatusChange: { todo in viewModel.advanceStatus(of: todo) },
            onUpdateStatus: { todo, status in viewModel.update(todo, to: status) },
            onDuplicate: { viewModel.duplicate($0) },
            onDelete: { viewModel.delete($0) },
          )
          .dropDestination(for: Todo.self) { items, _ in
            handleDrop(items, to: .complete)
          }
          .frame(width: columnWidth)

          if viewModel.scrollPosition == .trailing {
            TodoColumn(
              status: .inComplete,
              count: todos(for: .inComplete).count,
              tasks: todos(for: .inComplete),
              isToday: { Calendar.current.isDateInToday($0) },
              onTapTask: { presentTodoSheet(for: $0) },
              onStatusChange: { todo in viewModel.advanceStatus(of: todo) },
              onUpdateStatus: { todo, status in viewModel.update(todo, to: status) },
              onDuplicate: { viewModel.duplicate($0) },
              onDelete: { viewModel.delete($0) },
            )
            .dropDestination(for: Todo.self) { items, _ in
              handleDrop(items, to: .inComplete)
            }
            .frame(width: columnWidth)
            .transition(.move(edge: .trailing).combined(with: .opacity))
          }
        }
        .padding(.horizontal, horizontalMargin)
      }
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .accessibilityIdentifier("privateBoardView")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Menu {
          Picker("Date Filter", selection: $viewModel.dateFilter) {
            ForEach(DateFilter.allCases, id: \.self) { filter in
              Text(filter.rawValue).tag(filter)
            }
          }
          .pickerStyle(.inline)
        } label: {
          Image(
            systemName: viewModel.dateFilter == .today
              ? "line.3.horizontal.decrease.circle"
              : "line.3.horizontal.decrease.circle.fill",
          )
          .foregroundStyle(
            viewModel.dateFilter == .today ? .secondary : DesignSystem.Colors.primary,
          )
          .contentTransition(.symbolEffect(.replace))
        }
        .menuIndicator(.hidden)
      }

      HomeToolbarContent()
    }
  }

  // MARK: - Subviews

  private var header: some View {
    HStack(alignment: .bottom) {
      VStack(alignment: .leading, spacing: 4) {
        Text(Date().formatted(date: .complete, time: .omitted))
          .font(.title)
          .foregroundStyle(.primary)
      }

      Spacer()

      HStack(spacing: 8) {
        Button {
          withAnimation(.smooth) { viewModel.scrollPosition = .leading }
        } label: {
          Image(systemName: "chevron.left.2")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(viewModel.scrollPosition == .leading ? .tertiary : .primary)
        }
        .disabled(viewModel.scrollPosition == .leading)
        .buttonStyle(.plain)

        Button {
          withAnimation(.smooth) { viewModel.scrollPosition = .trailing }
        } label: {
          Image(systemName: "chevron.right.2")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(viewModel.scrollPosition == .trailing ? .tertiary : .primary)
        }
        .disabled(viewModel.scrollPosition == .trailing)
        .buttonStyle(.plain)
      }
      .padding(8)
      .background(.ultraThinMaterial)
      .clipShape(Capsule())
    }
  }

  // MARK: - Helpers

  @discardableResult
  private func handleDrop(_ items: [Todo], to status: TodoStatus) -> Bool {
    guard let todo = items.first else { return false }
    if todo.status != status {
      viewModel.update(todo, to: status)
    }
    return true
  }

  private func todos(for status: TodoStatus) -> [Todo] {
    viewModel.filteredTodos.filter { $0.status == status }
  }

  private func presentTodoSheet(for todo: Todo) {
    overlay?.presentCentered(
      backdropOpacity: 0.2,
    ) {
      TodoSheet(
        editableTodo: EditableTodo(from: todo),
      )
    }
  }
}

// MARK: - Todo Column

private struct TodoColumn: View {
  let status: TodoStatus
  let count: Int
  let tasks: [Todo]
  let isToday: (Date) -> Bool
  let onTapTask: (Todo) -> Void
  let onStatusChange: (Todo) -> Void
  let onUpdateStatus: (Todo, TodoStatus) -> Void
  let onDuplicate: (Todo) -> Void
  let onDelete: (Todo) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header
      HStack(spacing: 8) {
        Image(systemName: status.iconName)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(status.displayColor)

        Text(status.displayName)
          .font(.headline)
          .foregroundStyle(.primary)

        Text("\(count)")
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color(nsColor: .controlBackgroundColor))
          .clipShape(Capsule())

        Spacer()
      }
      .padding(.horizontal, 4)

      // List
      ScrollView(.vertical, showsIndicators: false) {
        LazyVStack(spacing: 12) {
          ForEach(tasks) { task in
            TodoCard(
              todo: task,
              onStatusClick: { onStatusChange(task) },
              onStatusChange: { status in onUpdateStatus(task, status) },
              onDuplicate: { onDuplicate(task) },
              onDelete: { onDelete(task) },
            )
            .draggable(task)
            .opacity(isToday(task.date) ? 1.0 : 0.6)
            .onTapGesture {
              onTapTask(task)
            }
          }
        }
      }
      .contentMargins(.bottom, 20, for: .scrollContent)
    }
  }
}
