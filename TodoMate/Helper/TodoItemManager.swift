//
//  TodoItemManager.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//

import SwiftUI
import SwiftData

@Observable
class TodoItemManager {
    private var todoItemRepository: TodoItemRepository
    var todoItems: [TodoItem] = []
    
    init(todoItemRepository: TodoItemRepository) {
        self.todoItemRepository = todoItemRepository
    }
}

extension TodoItemManager {
    func create(modelContext: ModelContext) {
        todoItemRepository.createTodoItem(modelContext: modelContext)
        fetch(modelContext: modelContext)
    }
    
    func fetch(modelContext: ModelContext, _ date: Date = .now) {
        todoItems = todoItemRepository.fetchTodoItem(modelContext: modelContext, date)
    }
    
    func update(modelContext: ModelContext, _ todo: TodoItem) {
        todoItemRepository.updateTodoItem(modelContext: modelContext, todo)
    }
    
    func remove(modelContext: ModelContext, _ todo: TodoItem) {
        guard let id = todo.pid else { return }
        
        todoItemRepository.deleteTodoItem(modelContext: modelContext, byID: id)
    }
    
}

/// todoItem 배열 관리
extension TodoItemManager {
    func move(from source: IndexSet, to destination: Int) {
        todoItems.move(fromOffsets: source, toOffset: destination)
    }
    
    func remove(_ todo: TodoItem){
        if let index = todoItems.firstIndex(where: { $0.id == todo.id }) {
            todoItems.remove(at: index)
        }
    }
}
