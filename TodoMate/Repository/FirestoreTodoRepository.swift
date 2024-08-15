//
//  TodoRepository.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import FirebaseFirestore

protocol TodoRepository {
    func fetchTodos(userId: String) async throws -> [TodoDTO]
    func createTodo(userId: String, todo: TodoDTO) async throws -> String
    func updateTodo(userId: String, todo: TodoDTO) async throws
    func deleteTodo(userId: String, todoId: String) async throws
}

class FirestoreTodoRepository: TodoRepository {
    private let reference: FirestoreReference
    
    init(reference: FirestoreReference = .shared) {
        self.reference = reference
    }
    
    func fetchTodos(userId: String) async throws -> [TodoDTO] {
        let snapshot = try await reference.todoCollection(userId: userId).getDocuments()
        
        return snapshot.documents.compactMap { document -> TodoDTO? in
            do {
                return try document.data(as: TodoDTO.self)
            } catch {
                print("Error decoding todo: \(error)")
                return nil
            }
        }
    }
    
    func createTodo(userId: String, todo: TodoDTO) async throws -> String {
        let todoDocRef = reference.todoCollection(userId: userId).document()
        var newTodo = todo
        newTodo.id = todoDocRef.documentID
        try todoDocRef.setData(from: newTodo)
        return todoDocRef.documentID
    }
    
    func updateTodo(userId: String, todo: TodoDTO) async throws {
        guard let todoId = todo.id else { return }
        let todoDocRef = reference.todoCollection(userId: userId).document(todoId)
        try todoDocRef.setData(from: todo)
    }
    
    func deleteTodo(userId: String, todoId: String) async throws {
        let todoDocRef = reference.todoCollection(userId: userId).document(todoId)
        try await todoDocRef.delete()
    }
}
