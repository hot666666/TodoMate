//
//  TodoMateWidget.swift
//  TodoMateWidget
//
//  Created by hs on 10/4/24.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    private let modelContext = ModelContext(Self.container)
    
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: .now, todos: TodoEntity.stub)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> ()) {
        let entry = TodoEntry(date: .now, todos: TodoEntity.stub)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> ()) {
        let todos = fetch()
        let entries: TodoEntry = .init(date: .now, todos: todos)
        let timeline = Timeline(entries: [entries], policy: .never)
        completion(timeline)
    }

    private func fetch() -> [TodoEntity] {
        do {
            let todoEntity = try modelContext.fetch(FetchDescriptor<TodoEntity>())
            return todoEntity
        } catch {
            return []
        }
    }
}
extension Provider {
    private static let container: ModelContainer = {
        do {
            return try ModelContainer(for: TodoEntity.self)
        } catch {
            print("Failed to create ModelContainer: \(error)")
            fatalError("\(error)")
        }
    }()
}
struct TodoEntry: TimelineEntry {
    let date: Date
    let todos: [TodoEntity]
}

struct TodoMateWidgetEntryView : View {
    var entry: TodoEntry

    var body: some View {
        VStack {
            ForEach(entry.todos) { todo in
                TodoListItem(todo: todo)
            }
        }
        if entry.todos.isEmpty {
            Text("진행 중인 Todo가 없습니다.")
        } else {
            Spacer()
        }
    }
}

struct TodoMateWidget: Widget {
    let kind: String = "TodoMateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodoMateWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("TodoMate Widget")
        .description("TodoMate Widget의 예시")
    }
}

