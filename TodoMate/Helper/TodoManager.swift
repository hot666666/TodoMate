//
//  TodoManager.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import SwiftUI

protocol TodoManagerProtocol {
    func create(_ todo: Todo) async
    func fetch() async
    func update(_ todo: Todo)
    func remove(_ todo: Todo)
}

@Observable
class TodoManager: TodoManagerProtocol {
    var todos: [Todo] = []

    private let todoRepository: TodoRepository
    private var userId: String
    
    
    init(userId: String,
         todoRepository: TodoRepository = FirestoreTodoRepository(reference: .shared)) {
        self.userId = userId
        self.todoRepository = todoRepository
    }
}

extension TodoManager {
    
    @MainActor
    func fetch() async {
        do {
            todos = try await todoRepository.fetchTodos(userId: userId).map { $0.toModel() }
        } catch {
            print("Error fetching todos: \(error)")
        }
    }
    
    func remove(_ todo: Todo) {
        Task {
            guard let todoId = todo.fid else { return }
            do {
                try await todoRepository.deleteTodo(userId: userId, todoId: todoId)
            } catch {
                print("Error deleting todo: \(error)")
            }
        }
    }
    
    func update(_ todo: Todo) {
        Task {
            do {
                try await todoRepository.updateTodo(userId: userId, todo: todo.toDTO())
            } catch {
                print("Error updating todo: \(error)")
            }
        }
    }
    
    @MainActor
    func create(_ todo: Todo) async {
        do {
            let id = try await todoRepository.createTodo(userId: userId, todo: todo.toDTO())
            todo.fid = id
        } catch {
            print("Error creating todo: \(error)")
        }
    }
}
