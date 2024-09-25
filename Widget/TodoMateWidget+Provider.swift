//
//  TodoMateWidget+Provider.swift
//  LearnWidgetKit
//
//  Created by hs on 9/11/24.
//

import WidgetKit
import SwiftUI

extension TodoMateWidget {
    struct Provider: TimelineProvider {
        func placeholder(in context: Context) -> Entry {
            .placeholder
        }

        func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
            completion(.placeholder)
        }

        func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
//            let todos = fetch()
//            completion(.init(entries: [.empty], policy: .never))
//            return
            
            let todos: [Todo] = Todo.widgetStub
            if todos.isEmpty {
                completion(.init(entries: [.empty], policy: .never))
                return
            }
    
            let entry = Entry(todos: todos)
            completion(.init(entries: [entry], policy: .never))
        }
    }
}

// MARK: - Helpers
extension TodoMateWidget.Provider {
    private func fetch() -> [Todo] {
        []
    }
}
