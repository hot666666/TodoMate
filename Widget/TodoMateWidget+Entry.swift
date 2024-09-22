//
//  TodoMateWidget+Entry.swift
//  LearnWidgetKit
//
//  Created by hs on 9/11/24.
//

import WidgetKit

extension TodoMateWidget {
    struct Entry: TimelineEntry {
        var date: Date = .now
        var todos: [Todo] = []
    }
}

// MARK: - Data
extension TodoMateWidget.Entry {
    static var empty: Self {
        .init()
    }

    static var placeholder: Self {
        .init(todos: Todo.widgetStub)
    }
}
