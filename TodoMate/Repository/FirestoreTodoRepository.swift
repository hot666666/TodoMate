//
//  TodoRepository.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import Foundation

protocol TodoRepositoryType {
    func createTodo(_ todo: TodoDTO) async throws -> TodoDTO
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
    func createTodo(_ todo: TodoDTO) async throws -> TodoDTO {
        let collectionRef = reference.todoCollection()
        let newDocReference = try collectionRef.addDocument(from: todo)
        let document = try await newDocReference.getDocument()
        return try document.data(as: TodoDTO.self)
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
    func createTodo(_ todo: TodoDTO) async throws -> TodoDTO {
        print("[Creating Todo] - \(todo)")
        
        return try reference.db.create(todo: todo)
    }
    
    func fetchTodos(userId: String, startDate: Date, endDate: Date) async throws -> [TodoDTO] {
        print("[Fetcing Todo] - \(userId)")
        
        let todos: [TodoDTO] = reference.db.read()
        return todos.filter { $0.uid == userId && startDate...endDate ~= $0.date }
    }
    
    func updateTodo(todo: TodoDTO) async throws {
        print("[Updating Todo] - \(todo)")
        
        try reference.db.update(todo: todo)
    }
    
    func deleteTodo(todoId: String) async throws {
        print("[Deleting Todo] - \(todoId)")
        
        try reference.db.delete(todoId: todoId)
    }
}
#endif
