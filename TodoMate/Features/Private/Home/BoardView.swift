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
  @Environment(LocalTodoHelper.self) private var todoStore
  @Environment(\.overlayManager) private var overlay

  @State private var dateFilter: DateFilter = .today

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Date Header (Toolbar handles filter, but we might show title here or in Toolbar)
      // Original code had date header in body. We keep similar layout.

      BoardQueryWrapper(
        dateFilter: dateFilter,
        onPresentSheet: presentTodoSheet,
      )
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .accessibilityIdentifier("privateBoardView")
    .toolbar {
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
          .foregroundStyle(
            dateFilter == .today ? .secondary : DesignSystem.Colors.primary,
          )
          .contentTransition(.symbolEffect(.replace))
        }
        .menuIndicator(.hidden)
      }

      HomeToolbarContent()
    }
  }

  // MARK: - Actions (Navigation/Sheet)

  private func presentTodoSheet(for originalTodo: Todo) {
    // Note: We need Todo, not ViewTodo, to create EditableTodo.
    // The Wrapper will provide the domain Todo object potentially,
    // or we fetch it? Wrapper has access to Domain Todo via SDTodo.
    // Let's make onPresentSheet take Todo.

    let editableTodo = EditableTodo(from: originalTodo)
    overlay?.presentCentered(
      id: .todoSheet,
      backdropOpacity: 0,
      offset: CGPoint(x: 0, y: -120),
    ) {
      TodoSheet(editableTodo: editableTodo)
    }
  }
}

// MARK: - BoardQueryWrapper (Data Access)

private struct BoardQueryWrapper: View {
  @Environment(LocalTodoHelper.self) private var todoStore
  @Query private var sdTodos: [SDTodo]

  let dateFilter: DateFilter
  let onPresentSheet: (Todo) -> Void

  init(dateFilter: DateFilter, onPresentSheet: @escaping (Todo) -> Void) {
    self.dateFilter = dateFilter
    self.onPresentSheet = onPresentSheet

    let range = dateFilter.dateRange
    let start = range.lowerBound
    let end = range.upperBound

    // Predicate
    let predicate = #Predicate<SDTodo> { todo in
      todo.date >= start && todo.date <= end && !todo.isDeleted
    }

    _sdTodos = Query(filter: predicate, sort: \SDTodo.date, order: .reverse)
  }

  var body: some View {
    // Mapping: SDTodo -> Todo -> ViewTodo
    // We compute viewTodos for rendering
    let viewTodos = sdTodos.map { ViewTodo(from: $0.toDomain()) }

    BoardContent(
      todos: viewTodos,
      onTapTask: { viewTodo in
        if let todo = findDomainTodo(for: viewTodo) {
          onPresentSheet(todo)
        }
      },
      onStatusClick: { viewTodo in
        cycleStatus(viewTodo)
      },
      onStatusChange: { viewTodo, status in
        updateTaskStatus(viewTodo, to: status)
      },
      onDropTask: { viewTodo, status in
        updateTaskStatus(viewTodo, to: status)
      },
      onDuplicateTask: { viewTodo in
        duplicateTask(viewTodo)
      },
      onDeleteTask: { viewTodo in
        deleteTask(viewTodo)
      },
    )
  }

  // MARK: - Data Helpers

  private func findDomainTodo(for viewTodo: ViewTodo) -> Todo? {
    sdTodos.first(where: { $0.id == viewTodo.id })?.toDomain()
  }

  private func cycleStatus(_ task: ViewTodo) {
    let nextStatus: ViewTodoStatus =
      switch task.status {
      case .todo: .inProgress
      case .inProgress: .done
      case .done: .todo
      case .inComplete: .todo
      }
    updateTaskStatus(task, to: nextStatus)
  }

  private func updateTaskStatus(_ task: ViewTodo, to newStatus: ViewTodoStatus) {
    guard let todo = findDomainTodo(for: task) else { return }
    todoStore.updateStatus(todo, status: newStatus.toDomainStatus())
  }

  private func duplicateTask(_ task: ViewTodo) {
    guard let todo = findDomainTodo(for: task) else { return }
    var newTodo = Todo.copy(from: todo)
    newTodo.detail = ""
    todoStore.addTodo(newTodo)
  }

  private func deleteTask(_ task: ViewTodo) {
    guard let todo = findDomainTodo(for: task) else { return }
    todoStore.deleteTodo(todo)
  }
}

// MARK: - BoardContent (Pure UI)

private struct BoardContent: View {
  let todos: [ViewTodo]

  // Actions
  let onTapTask: (ViewTodo) -> Void
  let onStatusClick: (ViewTodo) -> Void
  let onStatusChange: (ViewTodo, ViewTodoStatus) -> Void
  let onDropTask: (ViewTodo, ViewTodoStatus) -> Void
  let onDuplicateTask: (ViewTodo) -> Void
  let onDeleteTask: (ViewTodo) -> Void

  @State private var scrollPosition: BoardScrollPosition? = .leading

  // Filtered lists
  private var todoTasks: [ViewTodo] { todos.filter { $0.status == .todo } }
  private var inProgressTasks: [ViewTodo] { todos.filter { $0.status == .inProgress } }
  private var doneTasks: [ViewTodo] { todos.filter { $0.status == .done } }
  private var inCompleteTasks: [ViewTodo] { todos.filter { $0.status == .inComplete } }

  private func isToday(_ date: Date) -> Bool {
    Calendar.current.isDateInToday(date)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Header and Scroll Buttons
      HStack {
        Text(Date().formatted(.dateTime.year().month().day().weekday(.wide)))
          .font(.title)

        Spacer()

        HStack(spacing: 8) {
          Button {
            withAnimation(.smooth) { scrollPosition = .leading }
          } label: {
            Image(systemName: "chevron.left.2")
          }
          .disabled(scrollPosition == .leading)

          Button {
            withAnimation(.smooth) { scrollPosition = .trailing }
          } label: {
            Image(systemName: "chevron.right.2")
          }
          .disabled(scrollPosition == .trailing)
        }
        .buttonStyle(.borderless)
      }
      .padding(.horizontal)

      GeometryReader { proxy in
        let spacing: CGFloat = 16
        let horizontalMargin: CGFloat = 16
        let totalSpacing = spacing * 2
        let visibleWidth = proxy.size.width - (horizontalMargin * 2)
        let columnWidth = floor((visibleWidth - totalSpacing) / 3)

        HStack(alignment: .top, spacing: spacing) {
          if scrollPosition == .leading {
            TodoColumn(
              title: "To Do",
              count: todoTasks.count,
              color: .gray,
              tasks: todoTasks,
              isToday: isToday,
              onTapTask: onTapTask,
              onStatusClick: onStatusClick,
              onStatusChange: onStatusChange,
              onDropTask: { task in onDropTask(task, .todo) },
              onDuplicateTask: onDuplicateTask,
              onDeleteTask: onDeleteTask,
            )
            .frame(width: columnWidth)
            .transition(.move(edge: .leading).combined(with: .opacity))
          }

          TodoColumn(
            title: "In Progress",
            count: inProgressTasks.count,
            color: DesignSystem.Colors.accentCyan,
            tasks: inProgressTasks,
            isToday: isToday,
            onTapTask: onTapTask,
            onStatusClick: onStatusClick,
            onStatusChange: onStatusChange,
            onDropTask: { task in onDropTask(task, .inProgress) },
            onDuplicateTask: onDuplicateTask,
            onDeleteTask: onDeleteTask,
          )
          .frame(width: columnWidth)

          TodoColumn(
            title: "Done",
            count: doneTasks.count,
            color: DesignSystem.Colors.accentGreen,
            tasks: doneTasks,
            isToday: isToday,
            onTapTask: onTapTask,
            onStatusClick: onStatusClick,
            onStatusChange: onStatusChange,
            onDropTask: { task in onDropTask(task, .done) },
            onDuplicateTask: onDuplicateTask,
            onDeleteTask: onDeleteTask,
          )
          .frame(width: columnWidth)

          if scrollPosition == .trailing {
            TodoColumn(
              title: "Incomplete",
              count: inCompleteTasks.count,
              color: DesignSystem.Colors.accentRed,
              tasks: inCompleteTasks,
              isToday: isToday,
              onTapTask: onTapTask,
              onStatusClick: onStatusClick,
              onStatusChange: onStatusChange,
              onDropTask: { task in onDropTask(task, .inComplete) },
              onDuplicateTask: onDuplicateTask,
              onDeleteTask: onDeleteTask,
            )
            .frame(width: columnWidth)
            .transition(.move(edge: .trailing).combined(with: .opacity))
          }
        }
        .padding(.horizontal, horizontalMargin)
      }
    }
  }
}

// MARK: - Todo Column

private struct TodoColumn: View {
  let title: String
  let count: Int
  let color: Color
  let tasks: [ViewTodo]
  let isToday: (Date) -> Bool
  let onTapTask: (ViewTodo) -> Void
  let onStatusClick: (ViewTodo) -> Void
  let onStatusChange: (ViewTodo, ViewTodoStatus) -> Void
  let onDropTask: (ViewTodo) -> Void
  let onDuplicateTask: (ViewTodo) -> Void
  let onDeleteTask: (ViewTodo) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      columnHeader

      ScrollView(.vertical) {
        LazyVStack(spacing: 12) {
          ForEach(tasks) { task in
            TaskCard(
              task: task,
              onStatusClick: { onStatusClick(task) },
              onStatusChange: { status in onStatusChange(task, status) },
              onDuplicate: { onDuplicateTask(task) },
              onDelete: { onDeleteTask(task) },
            )
            .opacity(isToday(task.date) ? 1.0 : 0.3)
            .draggable(task)
            .onTapGesture {
              onTapTask(task)
            }
            .contextMenu {
              // TaskCard now builds its own context menu internally if Closures are set?
              // Wait, TaskCard handles its own context menu logic internally using environment or passed closures?
              // In my previous edit I added closures to TaskCard. PROPERTIES.
              // So I need to set them here.
              // But TaskCard is a struct. I need to modify the instance.
              // Or TaskCard init? No, it has `var onDuplicate`.
              // Swift Views are immutable. I should use modifiers or init.
              // TaskCard definition: `var onDuplicate: (() -> Void)?`
              // I can set it like `var card = TaskCard(...); card.onDuplicate = ...; return card` inside the loop?
              // Or add a modifier-like method to TaskCard if possible, or just init.
              // TaskCard is a View struct with properties.
              // I can initialize it with them if I change the init, OR use property injection syntax if they are vars?
              // `TaskCard(..., onDuplicate: { ... })` would be best if I update Init.
              // Current `TaskCard` has memberwise init because `onDuplicate` is var.
              // But `onStatusClick` was var too.
              // Let's use property syntax or helper.
              // Since I cannot easily change init call site everywhere if I change init, I'll use property syntax if I can.
              // `TaskCard(...)`.onDuplicate(...) if I make an extension?
              // Or just:
              // var card = TaskCard(...)
              // card.onDuplicate = ... -> Error: View is immutable value type.
              // Correct way: Pass in init.
              // `TaskCard` has free init.
            }
          }
        }
      }
      .contentMargins(.bottom, 20, for: .scrollContent)
    }
    .dropDestination(for: ViewTodo.self) { items, _ in
      if let task = items.first {
        onDropTask(task) // Callback handles status update
        return true
      }
      return false
    }
  }

  private var columnHeader: some View {
    HStack {
      Circle()
        .fill(color)
        .frame(width: 10, height: 10)

      Text(title)
        .font(.headline)

      Text("\(count)")
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.1))
        .clipShape(.capsule)

      Spacer()
    }
  }
}

#Preview {
  BoardView()
    .environment(LocalTodoHelper.preview)
    .environment(OverlayManager())
}
