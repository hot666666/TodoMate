//
//  TodoMateWidget.swift
//  TodoMateWidget
//
//  Modern widget displaying in-progress todos with completion buttons.
//
//  Created by hs on 1/15/26.
//

import AppIntents
import Common
import SwiftData
import SwiftUI
import TodoMateData
import TodoMateDomain
import WidgetKit

// MARK: - Timeline Entry

struct TodoWidgetEntry: TimelineEntry {
  let date: Date
  let todos: [WidgetTodo]
  let isEmpty: Bool
  let isAllCompleted: Bool
}

// MARK: - Widget Todo Model

struct WidgetTodo: Identifiable {
  let id: String
  let content: String
  let detail: String
}

// MARK: - Shared Model Container

@MainActor
enum WidgetDataContainer {
  static let shared: ModelContainer = {
    let schema = Schema([SDTodo.self, SDMemo.self])
    let config = ModelConfiguration(
      AppEnvironment.Container.name,
      schema: schema,
      isStoredInMemoryOnly: false,
    )

    do {
      return try ModelContainer(for: schema, configurations: [config])
    } catch {
      fatalError("Failed to create widget model container: \(error)")
    }
  }()
}

// MARK: - Timeline Provider

struct TodoMateTimelineProvider: TimelineProvider {
  func placeholder(in _: Context) -> TodoWidgetEntry {
    TodoWidgetEntry(
      date: .now,
      todos: [
        WidgetTodo(id: "1", content: "샘플 할 일", detail: ""),
        WidgetTodo(id: "2", content: "진행 중인 작업", detail: ""),
      ],
      isEmpty: false,
      isAllCompleted: false,
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (TodoWidgetEntry) -> Void) {
    let entry = placeholder(in: context)
    completion(entry)
  }

  func getTimeline(in _: Context, completion: @escaping (Timeline<TodoWidgetEntry>) -> Void) {
    Task { @MainActor in
      let todos = fetchInProgressTodos()
      let hasTodosToday = hasAnyTodosToday()

      let isEmpty = todos.isEmpty
      let isAllCompleted = isEmpty && hasTodosToday

      let entry = TodoWidgetEntry(
        date: .now,
        todos: todos,
        isEmpty: isEmpty,
        isAllCompleted: isAllCompleted,
      )

      // Refresh at next midnight
      let nextMidnight =
        Calendar.current.nextDate(
          after: .now,
          matching: DateComponents(hour: 0, minute: 0),
          matchingPolicy: .nextTime,
        ) ?? .now.addingTimeInterval(3600)

      let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
      completion(timeline)
    }
  }

  @MainActor
  private func fetchInProgressTodos() -> [WidgetTodo] {
    do {
      let container = WidgetDataContainer.shared
      let context = ModelContext(container)

      let today = Calendar.current.startOfDay(for: .now)
      let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
      let inProgressStatus = "진행 중"

      let predicate = #Predicate<SDTodo> { todo in
        todo.date >= today && todo.date < tomorrow && todo.statusRawValue == inProgressStatus
          && todo.isDeleted == false
      }

      var descriptor = FetchDescriptor(predicate: predicate)
      descriptor.sortBy = [SortDescriptor(\SDTodo.createdAt, order: .forward)]

      let sdTodos = try context.fetch(descriptor)
      return sdTodos.map { WidgetTodo(id: $0.id, content: $0.content, detail: $0.detail) }
    } catch {
      return []
    }
  }

  @MainActor
  private func hasAnyTodosToday() -> Bool {
    do {
      let container = WidgetDataContainer.shared
      let context = ModelContext(container)

      let today = Calendar.current.startOfDay(for: .now)
      let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

      let predicate = #Predicate<SDTodo> { todo in
        todo.date >= today && todo.date < tomorrow && todo.isDeleted == false
      }

      var descriptor = FetchDescriptor(predicate: predicate)
      descriptor.fetchLimit = 1

      return try context.fetchCount(descriptor) > 0
    } catch {
      return false
    }
  }
}

// MARK: - Widget Entry View

struct TodoMateWidgetEntryView: View {
  var entry: TodoWidgetEntry
  @Environment(\.widgetFamily) var family

  private var maxTodoCount: Int {
    switch family {
    case .systemSmall: 3
    case .systemMedium: 4
    case .systemLarge: 8
    default: 4
    }
  }

  var body: some View {
    Group {
      if entry.isAllCompleted {
        allCompletedView
      } else if entry.isEmpty {
        emptyView
      } else {
        todoListView
      }
    }
    .overlay(alignment: .topTrailing) {
      refreshButton
    }
    .containerBackground(.fill.tertiary, for: .widget)
  }

  private var refreshButton: some View {
    Button(intent: RefreshWidgetIntent()) {
      Image(systemName: "arrow.clockwise")
        .font(.caption)
    }
    .buttonStyle(.plain)
  }

  // MARK: - Todo List View

  private var todoListView: some View {
    VStack(alignment: .leading, spacing: 16) {
      headerView

      VStack(alignment: .leading, spacing: 6) {
        ForEach(entry.todos.prefix(maxTodoCount)) { todo in
          TodoRowView(todo: todo)
        }

        if entry.todos.count > maxTodoCount {
          Text("+\(entry.todos.count - maxTodoCount)개 더")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      .padding(8)

      Spacer(minLength: 0)
    }
  }

  private var headerView: some View {
    HStack {
      Image(systemName: "checklist")

      Text("진행 중")
        .font(.headline)

      Text("\(entry.todos.count)")
        .font(.caption)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.secondary.opacity(0.2))
        .clipShape(.capsule)

      Spacer()
    }
  }

  // MARK: - Empty State Views

  private var emptyView: some View {
    VStack(spacing: 8) {
      Image(systemName: "tray")
        .font(.largeTitle)
        .foregroundStyle(.secondary)

      Text("오늘 할 일이 없어요")
        .font(.headline)

      Text("새 할 일을 추가해보세요")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }

  private var allCompletedView: some View {
    ViewThatFits {
      // 공간 충분할 때
      VStack(spacing: 8) {
        Image(systemName: "checkmark.circle.fill")
          .font(.largeTitle)
          .foregroundStyle(.green)

        Text("모두 완료했어요!")
          .font(.headline)

        Text("오늘도 수고하셨습니다 🎉")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      // 공간 부족할 때
      VStack(spacing: 4) {
        Image(systemName: "checkmark.circle.fill")
          .font(.title2)
          .foregroundStyle(.green)

        Text("모두 완료!")
          .font(.subheadline)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Todo Row View

private struct TodoRowView: View {
  let todo: WidgetTodo

  var body: some View {
    HStack(spacing: 8) {
      Button(intent: ToggleTodoStatusIntent(todoId: todo.id)) {
        Image(systemName: "arrow.right.circle.fill")
          .font(.system(size: 16))
          .foregroundStyle(.blue)
      }
      .buttonStyle(.plain)

      VStack(alignment: .leading, spacing: 2) {
        Text(todo.content.isEmpty ? "이름없음" : todo.content)
          .font(.subheadline)
          .lineLimit(1)

        if !todo.detail.isEmpty {
          Text(todo.detail)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }

      Spacer(minLength: 0)
    }
  }
}

// MARK: - Widget Configuration

struct TodoMateWidget: Widget {
  #if DEBUG
    let kind = "TodoMateWidgetDev"
  #else
    let kind = "TodoMateWidget"
  #endif

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: TodoMateTimelineProvider()) { entry in
      TodoMateWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("진행 중인 할 일")
    .description("오늘의 진행 중인 할 일을 확인하고 완료 처리하세요.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
  TodoMateWidget()
} timeline: {
  TodoWidgetEntry(
    date: .now,
    todos: [
      WidgetTodo(id: "1", content: "Design review", detail: ""),
      WidgetTodo(id: "2", content: "Code cleanup", detail: "Refactor utils"),
    ],
    isEmpty: false,
    isAllCompleted: false,
  )
}

#Preview("Empty", as: .systemSmall) {
  TodoMateWidget()
} timeline: {
  TodoWidgetEntry(date: .now, todos: [], isEmpty: true, isAllCompleted: false)
}

#Preview("All Completed", as: .systemSmall) {
  TodoMateWidget()
} timeline: {
  TodoWidgetEntry(date: .now, todos: [], isEmpty: true, isAllCompleted: true)
}
