//
//  TodoListViewModel.swift
//  TodoMate
//
//  Created by hs on 8/21/24.
//

import SwiftUI

@Observable
class TodoBoxViewModel {
    private let container: DIContainer
    private let userId: String
    
    private var hoveringTodoId: String? = nil
    private let calendar: Calendar = .current
    
    var todos: [Todo] = []
    
    init(
        container: DIContainer,
        userId: String
    ) {
        self.container = container
        self.userId = userId
    }
    
    func onAppear() {
        container.todoRealtimeService.addObserver(self, for: userId)
    }
    
    func onDisappear() {
        container.todoRealtimeService.removeObserver(self, for: userId)
    }
}

extension TodoBoxViewModel {
    func create() {
        container.todoService.create(.init(date: .now, uid: userId))
    }
    
    @MainActor
    func fetch() async {
        todos = await  container.todoService.fetchToday(userId: userId)
    }
    
    func update(_ todo: Todo) {
        container.todoService.update(todo)
    }
    
    func remove(_ todo: Todo) {
        container.todoService.remove(todo)
    }
}

extension TodoBoxViewModel {
    func move(from source: IndexSet, to destination: Int) {
        todos.move(fromOffsets: source, toOffset: destination)
    }
    
    func setHoveringTodo(_ id: String?) {
        hoveringTodoId = id
    }

    func isHovering(_ todo: Todo) -> Bool {
        return hoveringTodoId == todo.id
    }
}

extension TodoBoxViewModel: TodoObserver {
    func todoAdded(_ todo: Todo) {
        guard calendar.isDateInToday(todo.date) else { return }
        todos.append(todo)
    }
    
    func todoModified(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.fid == todo.fid }) {
            if calendar.isDateInToday(todo.date) {
                todos[index] = todo
            } else {
                todos.remove(at: index)
            }
            return
        }
        
        guard calendar.isDateInToday(todo.date) else { return }
            todos.append(todo)
    }
    
    func todoRemoved(_ todo: Todo) {
        guard calendar.isDateInToday(todo.date) else { return }
        self.todos.removeAll { $0.fid == todo.fid }
    }
}
