//
//  TodoMateWidget.swift
//  TodoMateWidget
//
//  Created by hs on 3/9/25.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - TodoMateWidget
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

// MARK: - TodoEntity
struct TodoEntry: TimelineEntry {
    let date: Date
    let todos: [WidgetTodo]
}

// MARK: - TodoMateWidgetEntryView
struct TodoMateWidgetEntryView : View {
    var entry: TodoEntry

    var body: some View {
        VStack {
            ForEach(entry.todos) { todo in
                TodoRow(todo: todo)
            }
        }
        if entry.todos.isEmpty {
            Text("진행 중인 나의 Todo가 없습니다.")
        } else {
            Spacer()
        }
    }
}

// MARK: - Provider
struct Provider: TimelineProvider {
    private let modelContext = ModelContext(Self.container)
    
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: .now, todos: WidgetTodo.stub)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> ()) {
        let entry = TodoEntry(date: .now, todos: WidgetTodo.stub)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> ()) {
        // 엔트리 생성
        let todos = fetch()
        let entries: TodoEntry = .init(date: .now, todos: todos)
        // 타임라인 생성(with 엔트리)
        let timeline = Timeline(entries: [entries], policy: .never)
        // completion에 타임라인 전달
        completion(timeline)
    }

    private func fetch() -> [WidgetTodo] {
        do {
            let WidgetTodo = try modelContext.fetch(FetchDescriptor<WidgetTodo>())
            return WidgetTodo
        } catch {
            return []
        }
    }
}
extension Provider {
    private static let container: ModelContainer = {
        do {
            return try ModelContainer(for: WidgetTodo.self)
        } catch {
            print("Failed to create ModelContainer: \(error)")
            fatalError("\(error)")
        }
    }()
}
