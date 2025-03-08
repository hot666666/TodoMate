//
//  TodoService.swift
//  TodoMate
//
//  Created by hs on 1/7/25.
//

import Foundation

final class TodoService: TodoServiceType {
    private let todoRepository: TodoRepositoryType
    private let calendar: Calendar = .current

    init(todoRepository: TodoRepositoryType = FirestoreTodoRepository(reference: .shared)) {
        self.todoRepository = todoRepository
    }
}
extension TodoService {
    func create(from todo: Todo) async -> Todo? {
        do {
            let todoDTO = try await todoRepository.createTodo(todo.toDTO())
            return try? todoDTO.toModel()
        } catch {
            print("Error creating todo: \(error)")
            return nil
        }
    }

    func fetchMonth(userId: String, startDate: Date, endDate: Date) async -> [Date: [Todo]] {
        print("[Fetching Month for \(userId)] - ")
        do {
            let fetchedTodos = try await todoRepository.fetchTodos(userId: userId, startDate: startDate, endDate: endDate).map { try $0.toModel() }
            // MEMO: - Dictionary with reduce
            return fetchedTodos.reduce(into: [:]) { todosGroupedByDate, todo in
                let todoDate = calendar.startOfDay(for: todo.date)
                todosGroupedByDate[todoDate, default: []].append(todo)
            }
        } catch {
            print("Error fetching todos: \(error)")
            return [:]
        }
    }
    
    func fetchToday(groupId: String) async -> [Todo] {
        print("[Fetching Today for \(groupId)] - ")
        do {
            let today = Date.now
            let startDate = calendar.startOfDay(for: today)
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: startDate)!
            let endDate = calendar.date(byAdding: .second, value: -1, to: tomorrow)!
            return try await todoRepository.fetchTodos(groupId: groupId, startDate: startDate, endDate: endDate).map { try $0.toModel() }
        } catch {
            print("Error fetching today todos: \(error)")
            return []
        }
    }

    func update(_ todo: Todo) {
        print("[Updating Todo - \(todo)]")
        Task {
            do {
                try await todoRepository.updateTodo(todo: todo.toDTO())
            } catch {
                print("Error updating todo: \(error)")
            }
        }
    }

    func remove(_ todo: Todo) {
        print("[Removing Todo - \(todo)]")
        Task {
            do {
                try await todoRepository.deleteTodo(todoId: todo.fid)
            } catch {
                print("Error deleting todo: \(error)")
            }
        }
    }
}

