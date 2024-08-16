//
//  TodoManager.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import SwiftUI
import FirebaseFirestore

protocol TodoManagerProtocol {
    var todos: [Todo] { get set }
    func create(_ todo: Todo) async
    func fetch() async
    func update(_ todo: Todo)
    func remove(_ todo: Todo)
}

@Observable
class TodoManager: TodoManagerProtocol {
    var todos: [Todo] = []
    
    private let todoRepository: TodoRepository
    private var task: Task<Void, Never>?
    
    init(todoRepository: TodoRepository = FirestoreTodoRepository(reference: .shared)) {
        self.todoRepository = todoRepository
        setupRealtimeUpdates()
    }
    
    deinit {
        task?.cancel()
    }

}

extension TodoManager {
    private func setupRealtimeUpdates() {
        task = Task {
            for await change in todoRepository.observeTodoChanges() {
                print("[Observed change in FirebaseFirestore] - ", change)
                await handleDatabaseChange(change)
            }
        }
    }
    
    @MainActor
    private func handleDatabaseChange(_ change: DatabaseChange<TodoDTO>) {
        switch change {
        case .added(let todoDTO):
            let todo = todoDTO.toModel()
            if !todos.contains(where: { $0.fid == todo.fid }) {
                todos.append(todo)
            }
        case .modified(let todoDTO):
            if let index = todos.firstIndex(where: { $0.fid == todoDTO.id }) {
                todos[index] = todoDTO.toModel()
            }
        case .removed(let id):
            todos.removeAll { $0.fid == id }
        }
    }
}

extension TodoManager {
    @MainActor
    func fetch() async {
        do {
            todos = try await todoRepository.fetchTodos().map { $0.toModel() }
        } catch {
            print("Error fetching todos: \(error)")
        }
    }
    
    func remove(_ todo: Todo) {
        Task {
            guard let todoId = todo.fid else { return }
            do {
                try await todoRepository.deleteTodo(todoId: todoId)
            } catch {
                print("Error deleting todo: \(error)")
            }
        }
    }
    
    func update(_ todo: Todo) {
        Task {
            do {
                try await todoRepository.updateTodo(todo: todo.toDTO())
            } catch {
                print("Error updating todo: \(error)")
            }
        }
    }
    
    @MainActor
    func create(_ todo: Todo) async {
        do {
            let id = try await todoRepository.createTodo(todo: todo.toDTO())
            todo.fid = id
        } catch {
            print("Error creating todo: \(error)")
        }
    }
}

@Observable
class StubTodoManager: TodoManagerProtocol {
    var todos: [Todo]
    
    init(todos: [Todo] = []) {
        self.todos = todos
    }
    
    func fetch() async {
        todos = Todo.stub
    }
    
    func remove(_ todo: Todo) {
        todos.removeAll { $0.fid == todo.fid }
    }
    
    func update(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.fid == todo.fid }) {
            todos[index] = todo
        }
    }
    
    @MainActor
    func create(_ todo: Todo) async {
        todo.fid = UUID().uuidString /// Firebase에 업데이트되면 얻는 고유 ID 과정
        todos.append(todo)
    }
}
