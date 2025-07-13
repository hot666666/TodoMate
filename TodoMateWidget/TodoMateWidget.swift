//
//  TodoMateWidget.swift
//  TodoMateWidget
//
//  Created by hs on 3/9/25.
//

import SwiftData
import SwiftUI
import WidgetKit

// MARK: - TodoMateWidget

struct TodoMateWidget: Widget {
  let kind: String = "TodoMateWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      TodoMateWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("TodoMate 위젯")
    .description("진행 중인 할 일을 빠르게 확인하세요")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

// MARK: - TodoEntry

struct TodoEntry: TimelineEntry {
  let date: Date
  let todos: [WidgetTodo]
}

extension TodoEntry {
  static let placeholder = TodoEntry(
    date: Date(),
    todos: [
      WidgetTodo(id: "1", content: "할 일 예 1"),
      WidgetTodo(id: "2", content: "할 일 예 2"),
      WidgetTodo(id: "3", content: "할 일 예 3"),
    ]
  )
}

// MARK: - TodoMateWidgetEntryView

struct TodoMateWidgetEntryView: View {
  var entry: TodoEntry

  var body: some View {
    VStack(alignment: .leading) {
      if entry.todos.isEmpty {
        // 빈 상태
        Text("진행 중인 할 일이 없습니다")
          .font(.callout)
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else {
        // Todo 리스트
        VStack(alignment: .leading, spacing: 3) {
          ForEach(entry.todos.prefix(3)) { todo in
            TodoRow(todo: todo)
          }

          if entry.todos.count > 3 {
            Text("외 \(entry.todos.count - 3)개...")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .frame(maxHeight: .infinity, alignment: .top)
    .padding(5)
  }
}

// MARK: - Provider

struct Provider: TimelineProvider {
  private let modelContext = ModelContext(Self.container)

  func placeholder(in _: Context) -> TodoEntry {
    TodoEntry.placeholder
  }

  func getSnapshot(in _: Context, completion: @escaping (TodoEntry) -> Void) {
    completion(TodoEntry.placeholder)
  }

  func getTimeline(in _: Context, completion: @escaping (Timeline<TodoEntry>) -> Void) {
    do {
      let inProgressTodos = try fetch()

      let entry = TodoEntry(
        date: Date(),
        todos: inProgressTodos
      )

      let timeline = Timeline(entries: [entry], policy: .never)
      completion(timeline)
    } catch {
      print("[Widget] Error loading todos: \(error)")
      let errorEntry = TodoEntry(date: Date(), todos: [])
      let timeline = Timeline(entries: [errorEntry], policy: .never)
      completion(timeline)
    }
  }

  private func fetch() throws -> [WidgetTodo] {
    let fetchDescriptor = FetchDescriptor<WidgetTodo>()
    return try modelContext.fetch(fetchDescriptor)
  }
}

extension Provider {
  private static let container: ModelContainer = {
    do {
      return try ModelContainer(for: WidgetTodo.self)
    } catch {
      print("[Widget] - Failed to create ModelContainer: \(error)")
      fatalError("\(error)")
    }
  }()
}
