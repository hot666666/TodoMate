//
//  BoardView.swift
//  TodoMate
//
//  Kanban-style board view for tasks
//  Created by agent on 1/5/26.
//
//

import SimpleOverlaySystem
import SwiftUI
import TodoMateDomain

// MARK: - BoardView

struct BoardView: View {
  // MARK: - Environment

  @Environment(\.overlayManager) private var overlay
  @Environment(TodoBoardStore.self) private var store

  // MARK: - State

  @State private var dateFilter: DateFilter = .today
  @State private var scrollPosition: BoardScrollPosition? = .leading

  // MARK: - Computed Properties

  private var visibleStatuses: [TodoStatus] {
    switch scrollPosition ?? .leading {
    case .leading:
      [.todo, .inProgress, .complete]
    case .trailing:
      [.inProgress, .complete, .inComplete]
    }
  }

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      header
        .padding(.horizontal)
        .padding(.top, 8)

      columnsLayout
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .accessibilityIdentifier("privateBoardView")
    .toolbar {
      dateFilterMenu
      HomeToolbarContent()
    }
  }

  // MARK: - Subviews

  private var header: some View {
    HStack(alignment: .bottom) {
      Text(Date().formatted(date: .complete, time: .omitted))
        .font(.title)
        .foregroundStyle(.primary)

      Spacer()

      scrollPositionControl
    }
  }

  private var scrollPositionControl: some View {
    HStack(spacing: 8) {
      Button {
        withAnimation(.smooth) { scrollPosition = .leading }
      } label: {
        Image(systemName: "chevron.left.2")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(scrollPosition == .leading ? .tertiary : .primary)
      }
      .disabled(scrollPosition == .leading)
      .buttonStyle(.plain)

      Button {
        withAnimation(.smooth) { scrollPosition = .trailing }
      } label: {
        Image(systemName: "chevron.right.2")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(scrollPosition == .trailing ? .tertiary : .primary)
      }
      .disabled(scrollPosition == .trailing)
      .buttonStyle(.plain)
    }
    .padding(8)
    .background(.ultraThinMaterial)
    .clipShape(Capsule())
  }

  private var columnsLayout: some View {
    GeometryReader { proxy in
      let spacing: CGFloat = 16
      let horizontalMargin: CGFloat = 16
      let visibleWidth = max(0, proxy.size.width - (horizontalMargin * 2))
      let columnWidth = max(0, floor((visibleWidth - spacing * 2) / 3))

      HStack(alignment: .top, spacing: spacing) {
        ForEach(visibleStatuses, id: \.self) { status in
          TodoColumnContent(
            status: status,
            todos: todos(for: status),
            onTapTodo: { presentTodoSheet(for: $0) },
            onAdvanceStatus: advanceStatus,
            onUpdateStatus: updateStatus,
            onDuplicate: duplicate,
            onDelete: delete,
          )
          .dropDestination(for: Todo.self) { items, _ in
            handleDrop(items, to: status)
          }
          .frame(width: columnWidth)
          .transition(.move(edge: status == .todo ? .leading : .trailing).combined(with: .opacity))
        }
      }
      .padding(.horizontal, horizontalMargin)
    }
  }

  @ToolbarContentBuilder
  private var dateFilterMenu: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Menu {
        Picker("Date Filter", selection: $dateFilter) {
          ForEach(DateFilter.allCases, id: \.self) { filter in
            Text(filter.rawValue).tag(filter)
          }
        }
        .pickerStyle(.inline)
      } label: {
        Image(
          systemName: dateFilter == .today
            ? "line.3.horizontal.decrease.circle"
            : "line.3.horizontal.decrease.circle.fill",
        )
        .foregroundStyle(dateFilter == .today ? .secondary : DesignSystem.Colors.primary)
        .contentTransition(.symbolEffect(.replace))
      }
      .menuIndicator(.hidden)
    }
  }

  // MARK: - Actions

  private func todos(for status: TodoStatus) -> [Todo] {
    let dateRange = dateFilter.dateRange
    return store.todos.filter { todo in
      todo.status == status && dateRange.contains(todo.date)
    }
  }

  private func advanceStatus(of todo: Todo) {
    store.updateStatus(todo, status: todo.status.next)
  }

  private func updateStatus(_ todo: Todo, to status: TodoStatus) {
    store.updateStatus(todo, status: status)
  }

  private func duplicate(_ todo: Todo) {
    var newTodo = Todo.copy(from: todo)
    newTodo.detail = ""
    store.addTodo(newTodo)
  }

  private func delete(_ todo: Todo) {
    store.deleteTodo(todo)
  }

  @discardableResult
  private func handleDrop(_ items: [Todo], to status: TodoStatus) -> Bool {
    guard let todo = items.first else { return false }
    if todo.status != status {
      updateStatus(todo, to: status)
    }
    return true
  }

  // MARK: - Presentation

  private func presentTodoSheet(for todo: Todo) {
    overlay?.presentCentered(id: .todoSheet,
                             backdropOpacity: 0,
                             offset: CGPoint(x: 0, y: -120)) {
      TodoSheet(editableTodo: EditableTodo(from: todo))
    }
  }
}

// MARK: - TodoColumnContent

private struct TodoColumnContent: View {
  let status: TodoStatus
  let todos: [Todo]
  let onTapTodo: (Todo) -> Void
  let onAdvanceStatus: (Todo) -> Void
  let onUpdateStatus: (Todo, TodoStatus) -> Void
  let onDuplicate: (Todo) -> Void
  let onDelete: (Todo) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      columnHeader
      todoList
    }
  }

  private var columnHeader: some View {
    HStack(spacing: 8) {
      Image(systemName: status.iconName)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(status.displayColor)

      Text(status.displayName)
        .font(.headline)
        .foregroundStyle(.primary)

      Text("\(todos.count)")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(Capsule())

      Spacer()
    }
    .padding(.horizontal, 4)
  }

  private var todoList: some View {
    ScrollView(.vertical, showsIndicators: false) {
      LazyVStack(spacing: 12) {
        ForEach(todos) { todo in
          TodoCard(
            todo: todo,
            onStatusClick: { onAdvanceStatus(todo) },
            onStatusChange: { status in onUpdateStatus(todo, status) },
            onDuplicate: { onDuplicate(todo) },
            onDelete: { onDelete(todo) },
          )
          .draggable(todo)
          .opacity(Calendar.current.isDateInToday(todo.date) ? 1.0 : 0.6)
          .onTapGesture {
            onTapTodo(todo)
          }
        }
      }
    }
    .contentMargins(.bottom, 20, for: .scrollContent)
  }
}
