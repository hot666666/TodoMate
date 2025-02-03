//
//  TodoService.swift
//  TodoMate
//
//  Created by hs on 1/7/25.
//

import Foundation

protocol TodoServiceType {
    func create(_ todo: Todo)
    func create(from todo: Todo) async -> Todo?
    func fetchMonth(userId: String, startDate: Date, endDate: Date) async -> [Date: [Todo]]
    func fetchToday(userId: String) async -> [Todo]
    func update(_ todo: Todo)
    func remove(_ todo: Todo)
}

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
            return todoDTO.toModel()
        } catch {
            print("Error creating todo: \(error)")
            return nil
        }
    }

    
    func create(_ todo: Todo) {
        print("[creating Todo - \(todo.uid)")
        Task {
            do {
                try await todoRepository.createTodo(todo: todo.toDTO())
            } catch {
                print("Error creating todo: \(error)")
            }

        }
    }

    func fetchMonth(userId: String, startDate: Date, endDate: Date) async -> [Date: [Todo]] {
        print("[Fetching Month for \(userId)] - ")
        do {
            let fetchedTodos = try await todoRepository.fetchTodos(userId: userId, startDate: startDate, endDate: endDate).map { $0.toModel() }
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

    func fetchToday(userId: String) async -> [Todo] {
        print("[Fetching Today for \(userId)] - ")
        do {
            let today = Date.now
            let startDate = calendar.startOfDay(for: today)
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: startDate)!
            let endDate = calendar.date(byAdding: .second, value: -1, to: tomorrow)!
            return try await todoRepository.fetchTodos(userId: userId, startDate: startDate, endDate: endDate).map { $0.toModel() }
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
            guard let todoId = todo.fid else { return }
            do {
                try await todoRepository.deleteTodo(todoId: todoId)
            } catch {
                print("Error deleting todo: \(error)")
            }
        }
    }
}

class StubTodoService: TodoServiceType {
    private let calendar = Calendar.current
    
    func create(from todo: Todo) async -> Todo? {
        todo.fid = UUID().uuidString
        return todo
    }
    
    func create(_ todo: Todo) {
        
    }
    
    func fetchMonth(userId: String, startDate: Date, endDate: Date) async -> [Date : [Todo]] {
        let todos = Todo.stub.filter { $0.uid == userId && startDate...endDate ~= $0.date }
        return todos.reduce(into: [:]) { todosGroupByDate, todo in
            todosGroupByDate[calendar.startOfDay(for: todo.date), default: []].append(todo)
        }
    }
    
    func fetchToday(userId: String) async -> [Todo] {
        Todo.stub.filter { calendar.isDateInToday($0.date) && $0.uid == userId }
    }
    
    func update(_ todo: Todo) {
        
    }
    
    func remove(_ todo: Todo) {
        
    }
}
