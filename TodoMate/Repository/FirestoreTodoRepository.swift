//
//  TodoRepository.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import Foundation

protocol TodoRepositoryType {
    func createTodo(todo: TodoDTO) async throws
    func fetchTodos(userId: String, startDate: Date, endDate: Date) async throws -> [TodoDTO]
    func updateTodo(todo: TodoDTO) async throws
    func deleteTodo(todoId: String) async throws
}

final class FirestoreTodoRepository: TodoRepositoryType {
    private let reference: FirestoreReference
    
    init(reference: FirestoreReference = .shared) {
        self.reference = reference
    }
}
#if !PREVIEW
extension FirestoreTodoRepository {
    func createTodo(todo: TodoDTO) async throws {
        let todoDocRef = reference.todoCollection().document()
        var newTodo = todo
        newTodo.id = todoDocRef.documentID
        try todoDocRef.setData(from: newTodo)
    }
    
    func fetchTodos(userId: String, startDate: Date, endDate: Date) async throws -> [TodoDTO] {
        let snapshot = try await reference.todoCollection()
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .whereField("date", isLessThanOrEqualTo: endDate)
            .whereField("uid", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> TodoDTO? in
            do {
                return try document.data(as: TodoDTO.self)
            } catch {
                print("Error decoding todo: \(error)")
                return nil
            }
        }
    }
    
    func updateTodo(todo: TodoDTO) async throws {
        guard let todoId = todo.id else { return }
        let todoDocRef = reference.todoCollection().document(todoId)
        try todoDocRef.setData(from: todo)
    }
    
    func deleteTodo(todoId: String) async throws {
        let todoDocRef = reference.todoCollection().document(todoId)
        try await todoDocRef.delete()
    }
}
#else
extension FirestoreTodoRepository {
    func createTodo(todo: TodoDTO) async throws {
        print("[Creating Todo] - \(todo)")
    }
    
    func fetchTodos(userId: String, startDate: Date, endDate: Date) async throws -> [TodoDTO] {
        return TodoDTO.stub
    }
    
    func updateTodo(todo: TodoDTO) async throws {
        print("[Updating Todo] - \(todo)")
    }
    
    func deleteTodo(todoId: String) async throws {
        print("[Deleting Todo] - \(todoId)")
    }
}
#endif
