//
//  BoardView.swift
//  TodoMate
//
//  Kanban-style board view for tasks
//  Created by agent on 1/5/26.
//

import SimpleOverlaySystem
import SwiftUI
import TodoMateDomain

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

  private var headerTitle: String {
    Date().formatted(date: .complete, time: .omitted)
  }

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      header
      columnsLayout
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .accessibilityIdentifier("privateBoardView")
    .toolbar {
      dateFilterMenu
    }
  }

  private var header: some View {
    PageHeader(title: headerTitle) {
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
          BoardColumn(
            status: status,
            todos: todos(for: status),
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
    ToolbarItem(placement: .navigation) {
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

  @discardableResult
  private func handleDrop(_ items: [Todo], to status: TodoStatus) -> Bool {
    guard let todo = items.first else { return false }
    if todo.status != status {
      store.updateStatus(todo, status: status)
    }
    return true
  }
}
