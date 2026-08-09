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

// MARK: - Shared Database

enum WidgetDataContainer {
  static let database: GRDBDatabase = {
    do {
      return try GRDBDatabase()
    } catch {
      fatalError("Failed to create widget database: \(error)")
    }
  }()

  static let todoRepository = GRDBTodoRepository(database: database)
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
    Task {
      let todos = await fetchInProgressTodos()
      let hasTodosToday = await hasAnyTodosToday()

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

  private func fetchInProgressTodos() async -> [WidgetTodo] {
    do {
      let today = Calendar.current.startOfDay(for: .now)
      let end = Calendar.current.date(byAdding: .day, value: 1, to: today)!.addingTimeInterval(-1)
      let todos = try await WidgetDataContainer.todoRepository.readAll(
        query: TodoQuery().dateRange(today ... end).status(.inProgress),
        useCache: false,
      )
      return todos.map { WidgetTodo(id: $0.id, content: $0.content, detail: $0.detail) }
    } catch {
      Log.error("Widget todo fetch failed: \(error)", category: .data)
      return []
    }
  }

  private func hasAnyTodosToday() async -> Bool {
    do {
      let today = Calendar.current.startOfDay(for: .now)
      let end = Calendar.current.date(byAdding: .day, value: 1, to: today)!.addingTimeInterval(-1)
      return try await WidgetDataContainer.todoRepository.fetchCount(
        query: TodoQuery().dateRange(today ... end),
      ) > 0
    } catch {
      Log.error("Widget todo count failed: \(error)", category: .data)
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
