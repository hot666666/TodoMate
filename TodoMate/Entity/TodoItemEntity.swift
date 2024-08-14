//
//  TodoItemEntity.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//

import SwiftData
import Foundation

@Model
class TodoItemEntity {
    var date: Date
    var content: String
    var statusRawValue: String
    var detail: String
    var startTime: Date?
    var endTime: Date?
    
    @Transient
    var status: TodoItemStatus {
        get { TodoItemStatus(rawValue: statusRawValue) ?? .todo }
        set { statusRawValue = newValue.rawValue }
    }
    
    init() {
        self.date = .now
        self.content = ""
        self.statusRawValue = TodoItemStatus.todo.rawValue
        self.detail = ""
    }
    
    init(content: String, date: Date = .now, status: TodoItemStatus = .todo, detail: String = "") {
        self.date = date
        self.content = content
        self.statusRawValue = status.rawValue
        self.detail = detail
    }
}

extension TodoItemEntity {
    func toModel() -> TodoItem {
        TodoItem(date: self.date, content: self.content, detail: self.detail, status: self.status, pid: self.persistentModelID)
    }
}

extension TodoItemEntity {
    @MainActor 
    static func makeSampleTodoItems(in container: ModelContainer) {
        let context = container.mainContext

        let sampleItems = [
            TodoItemEntity(content: ""),
            TodoItemEntity(content: ""),
            TodoItemEntity(content: ""),
        ]

        for item in sampleItems {
            context.insert(item)
        }

        do {
            try context.save()
        } catch {
            print("Failed to save sample todo items: \(error)")
        }
    }
}
